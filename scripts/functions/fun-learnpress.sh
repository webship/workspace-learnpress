#!/usr/bin/env bash

# LearnPress for the Webship Workspace: build a site of courses on WordPress, add its default accounts (one per place in
# the courses), add the sample courses, and wire its step pack into the testing setup, next to the WordPress step pack
# it extends.
#
# Placed by `plugins.sh --install learnpress` in core/scripts/plugins/learnpress/functions/, where bootstrap sources it
# with the core's own functions and the WordPress plugin's: this plugin needs @webship.co/workspace-wordpress, and its
# builder starts from that plugin's wordpress_build. Everything runs in the project's container (DDEV by default:
# `ddev wp …`), never on the host. The container tool writes the database settings, so nothing here writes any.
#
# LearnPress's activation makes its tables, its pages (Courses, Profile, Checkout, Instructors, Become an Instructor,
# Terms and Conditions) and its roles. The accounts' places and the sample courses are written with the plugin's own
# models by learning-site.php (beside these functions), run with WP-CLI in the container:
#   bash cmd-tools-wordpress-cli.sh <site> --run "post list --post_type=lp_course"
#
# A site of courses is a project of the type `wordpress`. The builder leaves the claim of this plugin on the project,
# by which the core's tools take the test users of the courses for it instead of the WordPress list:
# .ddev/config.learnpress.yaml on DDEV, `platform: learnpress` in the x-webship block on another runtime.
#
# The runtimes: a site is built on DDEV, or with --runtime on Docker Compose, Podman, Kubernetes, Lando or Docksal. The
# WordPress plugin's builder makes the site on that runtime, and the commands here are the same on each: `ddev <verb>`
# is DDEV itself on a DDEV project, and on another runtime the core's layer (fun-runtime.sh) gives the verb its
# meaning. What differs is behind learnpress_runtime: the address (learnpress_url) and where the claim is.
#
# Four names are the ones the core's tools look for:
#   set_learnpress_users          the default accounts        (cmd-tools-add-users.sh <project> learnpress)
#   add_learnpress_users          create them with WP-CLI     (the same tool, and --add-users of the builder)
#   cancel_learnpress_users       delete them                 (cmd-tools-cancel-users.sh <project> learnpress)
#   testing_configure_learnpress  the step pack in the testing stack (cmd-tools-testing.sh <project>)

# The step pack a site of courses is tested with, and the release line it is required at. It brings the WordPress step
# pack along; the WordPress plugin's hook adds that one too.
readonly LEARNPRESS_STEPS_PACKAGE='@webship-js/learnpress-steps';
readonly LEARNPRESS_STEPS_VERSION='^2.0.0';

# The default accounts: one per place in the courses, the ones a scenario logs in as. Accounts are configuration,
# created once on the site; a test suite never creates or deletes one.
#   administrator  an administrator of the site (a second one: the installer's is the workspace account)
#   instructor     LearnPress's instructor role (lp_teacher): the sample courses are theirs
#   student        a subscriber enrolled in the first sample course
#   student2       a subscriber enrolled in nothing
# The name the site shows is "<Login> Test" ("Student2 Test").
function set_learnpress_users() {
  users=(administrator instructor student student2);
  local user ;
  for user in "${users[@]}" ; do
    printf -v "user_${user}_name" '%s' "${user}" ;
    printf -v "user_${user}_mail" '%s' "${user}@example.com" ;
    printf -v "user_${user}_password" '%s' 'dD.123123ddd' ;
    printf -v "user_${user}_role" '%s' 'subscriber' ;
    printf -v "user_${user}_fullname" '%s' "${user^} Test" ;
  done
  user_administrator_role='administrator' ;
  user_instructor_role='lp_teacher' ;
}

# The runtime of the project in this folder, or of a new build (--runtime, else the workspace's setting, else DDEV). A
# core without the runtime layer has DDEV only.
function learnpress_runtime() {
  if declare -f runtime_of > /dev/null ; then runtime_of ; else echo 'ddev' ; fi
}

# The address of the site in this folder: https://<name>.ddev.site on DDEV, http://127.0.0.1:<port> on Docker Compose,
# Podman and Lando, the node's address and a port on Kubernetes, http://<name>.docksal.site on Docksal. Asked once the
# project is configured.
function learnpress_url() {
  if declare -f rt_url > /dev/null ; then rt_url ; else echo "https://${PROJECT_NAME}.ddev.site" ; fi
}

# Is this folder a site of courses? The builder leaves its claim in it (the file on DDEV, the x-webship block on another
# runtime: the core's rt_is_platform reads both); a WordPress project that got the plugin another way has the plugin's
# folder, at its root or in its docroot.
function learnpress_is_project() {
  local project_path="$1" ;
  [ -f "${project_path}/.ddev/config.learnpress.yaml" ] && return 0 ;
  if declare -f rt_is_platform > /dev/null ; then
    rt_is_platform "${project_path}" learnpress && return 0 ;
  fi
  [ -f "${project_path}/wp-content/plugins/learnpress/learnpress.php" ] && return 0 ;
  compgen -G "${project_path}/*/wp-content/plugins/learnpress/learnpress.php" > /dev/null ;
}

# Go to the project a tool was asked about, or say why not.
function learnpress_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! learnpress_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not a site of courses: a WordPress project with LearnPress in its plugins." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# The claim of this plugin on a project, in the folder of the container tool: a config overlay with one key the web
# container does not use, the name of the platform the project was built as. The core's tools read the file's name: a
# project that carries config.<plugin>.yaml takes the test users of that plugin.
function learnpress_write_claim() {
  local project_path="$1" ;
  mkdir -p "${project_path}/.ddev" || return 1 ;
  cat > "${project_path}/.ddev/config.learnpress.yaml" <<'YAMLEOF'
# Written by the LearnPress plugin of the Webship Workspace (cmd-learnpress-project.sh).
#
# It is the plugin's claim on this project: the workspace's tools take the test users of the courses for it
# (cmd-tools-add-users.sh <project> learnpress) instead of the WordPress list. The key below is in the environment of
# the web container from its next start; nothing of the site reads it.
web_environment:
  - WEBSHIP_WORKSPACE_PLATFORM=learnpress
YAMLEOF
}

# Run learning-site.php in the site, in the project folder: the sample courses, a reset, a status, the counts, what
# deleted accounts left in the plugin's tables, each written or read with the plugin's own models.
function learnpress_learning_site() {
  local script="${WORKSPACE_SCRIPTS}/plugins/learnpress/learning-site.php" status ;
  if [ ! -f "${script}" ] ; then
    echo "The LearnPress plugin's learning-site.php is not at ${script}: install the plugin again (plugins.sh --install learnpress)." ;
    return 1 ;
  fi
  cp "${script}" .webship-learning-site.php || return 1 ;
  ddev wp eval-file .webship-learning-site.php "$@" < /dev/null ;
  status=$? ;
  rm -f .webship-learning-site.php ;
  return ${status} ;
}

# Build a site of courses from nothing: the WordPress plugin's builder makes the site, then LearnPress is added.
function learnpress_build() {
  trim_project_name ;
  local base_url runtime ;
  runtime="$(learnpress_runtime)" ;
  if [ "${RUNTIME:-_none_}" != '_none_' ] && [ "${RUNTIME}" != "${runtime}" ] ; then
    echo "--runtime ${RUNTIME} needs a Webship Workspace with the container runtimes (webship/workspace#694): update the workspace, or build on DDEV." ;
    exit 1 ;
  fi
  local learnpress_version="${VERSION:-${site_version:-latest}}" ;
  local add_users="${ADD_USERS}" launch="${LAUNCH}" ;

  if ! declare -f wordpress_build > /dev/null ; then
    echo "The LearnPress plugin builds on the WordPress plugin, which is not installed here:" ;
    echo "  bash core/scripts/plugins.sh --install wordpress" ;
    exit 1 ;
  fi

  # The site, by the WordPress plugin's builder: the container, WordPress, and with --install the site with the
  # workspace account as its administrator. Its --version is WordPress's; the accounts and the browser come after
  # LearnPress is set up.
  VERSION="${WORDPRESS_VERSION:-${wordpress_version:-latest}}" ;
  ADD_USERS='no' ; LAUNCH='no' ;
  ( wordpress_build ) || exit 1 ;
  ADD_USERS="${add_users}" ; LAUNCH="${launch}" ;

  cd "${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" || exit 1 ;
  # The address is the runtime's to say, now the project is configured: never a written ddev.site.
  base_url="$(learnpress_url)" ;
  # The claim: a file of the container tool's on DDEV, the x-webship block on another runtime.
  if [ "${runtime}" != 'ddev' ] ; then
    rt_claim learnpress || { echo "The plugin's claim on the project could not be written." ; exit 1 ; } ;
  else
    learnpress_write_claim "${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" || { echo "The plugin's claim on the project could not be written." ; exit 1 ; } ;
  fi

  if [ "${INSTALL}" != 'yes' ] ; then
    # No site yet: LearnPress goes into the plugins, to activate once WordPress is installed.
    local zip="learnpress.latest-stable.zip" ;
    [ "${learnpress_version}" != 'latest' ] && zip="learnpress.${learnpress_version}.zip" ;
    ddev exec "curl -fsSL https://downloads.wordpress.org/plugin/${zip} -o /tmp/learnpress.zip && unzip -oq /tmp/learnpress.zip -d wp-content/plugins && rm -f /tmp/learnpress.zip" < /dev/null \
      || { echo "LearnPress could not be downloaded." ; exit 1 ; } ;
    [ "${ADD_USERS}" == 'yes' ] && echo "--add-users needs --install: there is no site to add accounts to yet." ;
    [ "${SAMPLE_COURSE}" == 'yes' ] && echo "--sample-course needs --install: there are no courses to add it to yet." ;
    echo "${doc_name} ${PROJECT_NAME} is ready to install, with LearnPress in its plugins.";
    echo "Go to ${base_url}";
    cd ${WORKSPACE_ROOT}/${doc_name};
    return 0 ;
  fi

  # Pretty addresses (the courses live at /courses/, the profile at /profile/), then LearnPress: its activation makes
  # its tables, its pages and its roles.
  ddev wp rewrite structure '/%postname%/' < /dev/null > /dev/null ;
  ddev wp plugin install learnpress $( [ "${learnpress_version}" != 'latest' ] && echo "--version=${learnpress_version}" ) --activate < /dev/null \
    || { echo "LearnPress could not be installed." ; exit 1 ; } ;

  # The accounts before the courses: the sample courses are the instructor's, and the student is enrolled.
  if [ "${ADD_USERS}" == 'yes' ] ; then
    set_learnpress_users ;
    add_learnpress_users ;
    cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;
  fi

  if [ "${SAMPLE_COURSE}" == 'yes' ] ; then
    [ "${ADD_USERS}" == 'yes' ] || echo "Without --add-users the sample courses have only the accounts the site has." ;
    learnpress_learning_site content || { echo "The sample courses could not be added." ; exit 1 ; } ;
  fi

  # The addresses of the courses, lessons and quizzes answer once the rules are written again.
  ddev wp rewrite flush < /dev/null > /dev/null 2>&1 ;
  echo "${doc_name} ${PROJECT_NAME} has been installed: WordPress $(ddev wp core version 2>/dev/null < /dev/null), LearnPress $(ddev wp plugin get learnpress --field=version 2>/dev/null < /dev/null).";
  echo "Go to ${base_url}/courses/, and ${base_url}/wp-admin as ${account_name}";

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch /courses/ ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Create the default accounts with WP-CLI, each with its role on the site and the name the site shows; an account that
# is already there keeps its password and gets its role and its name back. The list is loaded by the caller
# (set_learnpress_users): the core's add_users, the builder, the courses' tool, the testing setup.
function add_learnpress_users() {
  learnpress_enter_project || return 1 ;
  local user user_name user_mail user_password user_role user_fullname ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail";
    user_password="user_${user}_password"; user_role="user_${user}_role"; user_fullname="user_${user}_fullname";

    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo "      User mail: ${!user_mail}";
    echo "  User password: ${!user_password}";
    echo "      User role: ${!user_role}";
    echo "   Display name: ${!user_fullname:-${!user_name}}";
    echo " ================================================================= ";

    if ddev wp user get "${!user_name}" --field=ID < /dev/null > /dev/null 2>&1 ; then
      echo "   ${!user_name} is already there." ;
      ddev wp user set-role "${!user_name}" "${!user_role}" < /dev/null > /dev/null ;
      ddev wp user update "${!user_name}" --display_name="${!user_fullname:-${!user_name}}" < /dev/null > /dev/null ;
    else
      ddev wp user create "${!user_name}" "${!user_mail}" --role="${!user_role}" --user_pass="${!user_password}" --display_name="${!user_fullname:-${!user_name}}" < /dev/null ;
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Delete the default accounts. WordPress deletes the instructor's courses, lessons, quizzes and questions with it, and
# the plugin's own tables keep what pointed at them (the accounts' enrolments, progress, history and orders, the
# sections of the courses and their items): learning-site.php takes that away once the accounts are gone. The sample
# courses come back with the accounts (--add-users, then --sample-course).
function cancel_learnpress_users() {
  learnpress_enter_project || return 1 ;
  local user user_name ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name";
    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo " ================================================================= ";
    if ddev wp user get "${!user_name}" --field=ID < /dev/null > /dev/null 2>&1 ; then
      ddev wp user delete "${!user_name}" --yes < /dev/null ;
    else
      echo "   ${!user_name} is not there." ;
    fi
  done
  learnpress_learning_site orphans || echo "   what the plugin's tables keep of the deleted accounts could not be taken away: is LearnPress active on the site?" ;
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# What cmd-tools-learnpress-courses.sh does: the first of --add-users, --cancel-users, --sample-course, --tidy that was
# asked for; with none of them, what the courses hold.
function learnpress_courses_tool() {
  trim_project_name ;
  learnpress_enter_project || exit 1 ;

  if ! ddev wp core is-installed < /dev/null > /dev/null 2>&1 ; then
    ddev start -y < /dev/null || exit 1 ;
  fi
  if ! ddev wp plugin is-active learnpress < /dev/null > /dev/null 2>&1 ; then
    echo "${doc_name}/${PROJECT_NAME}: LearnPress is not active on the site (is WordPress installed? bash cmd-tools-wordpress-cli.sh ${PROJECT_NAME})." ;
    exit 1 ;
  fi

  if [ "${ADD_USERS}" == 'yes' ] ; then
    set_learnpress_users ;
    add_learnpress_users ;
  elif [ "${CANCEL_USERS}" == 'yes' ] ; then
    set_learnpress_users ;
    cancel_learnpress_users ;
  elif [ "${SAMPLE_COURSE}" == 'yes' ] ; then
    learnpress_learning_site content || exit 1 ;
    ddev wp rewrite flush < /dev/null > /dev/null 2>&1 ;
  elif [ "${TIDY}" == 'yes' ] ; then
    learnpress_learning_site reset || exit 1 ;
    echo "The courses are back as the sample course left them." ;
  else
    echo "${doc_name}/${PROJECT_NAME}: LearnPress $(ddev wp plugin get learnpress --field=version 2>/dev/null < /dev/null) on WordPress $(ddev wp core version 2>/dev/null < /dev/null), at $(ddev wp option get siteurl 2>/dev/null < /dev/null)/courses/" ;
    echo "" ;
    learnpress_learning_site status || exit 1 ;
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of a site of courses. The core's testing_configure calls this in the project
# folder once webship-js is scaffolded and before the dependencies are installed; for a project without LearnPress it
# changes nothing.
#
# The courses' pack extends the WordPress pack, and both go in the same profile: the WordPress plugin's hook runs first
# (its pack, its users registry, its first feature), whichever order the core calls the hooks in; then this one adds
# its pack to package.json and its step definitions to cucumber.js, the tags that keep its assertions that must fail
# out of a normal run, the courses' handles in the users registry (with the names the site shows, by which a step tells
# the account logged in), and a first feature for the courses when the project has none. Every part is skipped when it
# is already there, so a second run adds what the first missed and never resets a suite.
function testing_configure_learnpress() {
  local project_path="$1";
  learnpress_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  LearnPress: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  if declare -f testing_configure_wordpress > /dev/null ; then
    testing_configure_wordpress "${project_path}" || return 1 ;
  fi

  echo "Adding the LearnPress step pack (${LEARNPRESS_STEPS_PACKAGE} ${LEARNPRESS_STEPS_VERSION}).";
  set_learnpress_users ;
  local registry="" user user_name user_mail user_password user_fullname handle ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail"; user_password="user_${user}_password"; user_fullname="user_${user}_fullname";
    # The WordPress pack's features call the administrator "admin".
    handle="${user}" ; [ "${user}" == 'administrator' ] && handle="admin" ;
    registry="${registry}${handle}|${!user_name}|${!user_password}|${!user_mail}|${!user_fullname}"$'\n' ;
  done

  python3 - "${project_path}" "${LEARNPRESS_STEPS_PACKAGE}" "${LEARNPRESS_STEPS_VERSION}" 'WP' "${registry}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version, prefix, registry = sys.argv[1:6]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

# The pack's step definitions, after webship-js's own (and the WordPress pack's, which it loads itself).
if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    anchor = re.search(r"^([ \t]*)'node_modules/@webship-js/wordpress-steps/tests/step-definitions/[^']*',.*$", src, re.M) \
        or re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if anchor:
        src = src[:anchor.end()] + '\n' + anchor.group(1) + line + src[anchor.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

# The pack's assertions that must fail are no part of a normal run.
if not re.search(r"^[ \t]*tags:", src, re.M):
    default = re.search(r"^([ \t]*)default:[ \t]*\{[ \t]*$", src, re.M)
    if default:
        pad = default.group(1) + '  '
        src = src[:default.end()] + '\n' + pad + "// Work in progress and the assertions that must fail (@must-fail) stay out of a normal run.\n" \
            + pad + "tags: process.env.CUCUMBER_TAGS || 'not @wip and not @must-fail'," + src[default.end():]
        print('  cucumber.js: the tags that keep the assertions that must fail out of a normal run')

world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)
if not world:
    sys.exit("  cucumber.js has no worldParameters block to add the users registry to.")
pad = world.group(1) + '  '

rows = [r.split('|') for r in registry.splitlines() if r.strip()]
entry = lambda handle, login, password, mail, name: "%s: { username: process.env.%s_%s_USER || '%s', password: process.env.%s_%s_PASSWORD || '%s', email: '%s', name: '%s' }," % (
    handle, prefix, handle.upper(), login, prefix, handle.upper(), password, mail, name)
users = re.search(r"^([ \t]*)users:[ \t]*\{[ \t]*$", src, re.M)
if users:
    # The registry the WordPress plugin wrote: the courses' handles it does not have go in at its start, and a handle it
    # has without an address or a name (admin) gets the address and the name the site shows.
    missing = [r for r in rows if not re.search(r"^[ \t]*%s:[ \t]*\{" % re.escape(r[0]), src, re.M)]
    if missing:
        inner = users.group(1) + '  '
        src = src[:users.end()] + '\n' + '\n'.join(inner + entry(*r) for r in missing) + src[users.end():]
        print('  cucumber.js: the courses\' accounts in the users registry (%s)' % ', '.join(r[0] for r in missing))
    for handle, login, password, mail, name in rows:
        line = re.search(r"^([ \t]*%s:[ \t]*\{)([^\n]*)(\},?[ \t]*)$" % re.escape(handle), src, re.M)
        if line and 'email:' not in line.group(2):
            src = src[:line.start()] + line.group(1) + line.group(2).rstrip() + ", email: '%s' " % mail + line.group(3) + src[line.end():]
        line = re.search(r"^([ \t]*%s:[ \t]*\{)([^\n]*)(\},?[ \t]*)$" % re.escape(handle), src, re.M)
        if line and not re.search(r"(?<![A-Za-z_])name:", line.group(2)):
            src = src[:line.start()] + line.group(1) + line.group(2).rstrip() + ", name: '%s' " % name + line.group(3) + src[line.end():]
else:
    block = [
        pad + "// The users registry: a handle a scenario reads, mapped to an account of this site (the default",
        pad + "// accounts: cmd-tools-add-users.sh <project> learnpress). Override one with %s_<HANDLE>_USER and %s_<HANDLE>_PASSWORD." % (prefix, prefix),
        pad + "users: {",
    ] + [pad + '  ' + entry(*r) for r in rows] + [pad + "},"]
    src = src[:world.end()] + '\n' + '\n'.join(block) + src[world.end():]
    print('  cucumber.js: the users registry (%s)' % ', '.join(r[0] for r in rows))

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature for the courses, when the project has none: the course list, a course, each account in its place.
  local feature="${WORKSPACE_SCRIPTS}/plugins/learnpress/courses.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/courses.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/courses.feature" \
      && echo "  tests/features/courses.feature: a first feature for the courses" ;
  fi

  # The scenarios log in as the default accounts: make sure an installed site has them.
  if ddev wp core is-installed < /dev/null > /dev/null 2>&1 ; then
    ( add_learnpress_users > /dev/null ) && echo "  the default accounts of the courses are on the site (${users[*]})" ;
  fi
}
