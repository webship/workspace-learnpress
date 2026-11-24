# @webship.co/workspace-learnpress

LearnPress for the [Webship Workspace](https://github.com/webship/workspace) dashboard, on top of its
WordPress plugin ([`@webship.co/workspace-wordpress`](https://github.com/webship/workspace-wordpress)):
a builder that makes a real site of courses in a container — WordPress with the free LearnPress plugin, its
pages and its roles — the default accounts (one per place in the courses), the sample courses with their
lessons, a quiz and an enrolment, the courses' own tool, the
[LearnPress step pack](https://github.com/webship/learnpress-steps) wired into the workspace's testing setup
next to the WordPress one it extends, and its AI items — two agents, a skill, a command and two prompts — each
listed in the workspace folder of its kind.

The workspace is container-based (DDEV by default): a site of courses is a WordPress project like any other, so
the row menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it unchanged. The plugin
claims its sites with a file of its own (`.ddev/config.learnpress.yaml`), so the Tests menu of the row offers the
test users of the courses.

It is made from the reference platform plugin, `@webship.co/workspace-wordpress`, and builds on it: the site is
made by that plugin's builder, and WP-CLI is that plugin's tool (`cmd-tools-wordpress-cli.sh`).

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-learnpress --with-needs   # npm install into the dashboard, with the WordPress plugin
bash core/scripts/plugins.sh --activate learnpress --with-needs                         # plugins.learnpress in settings.yml, and what it needs
bash core/scripts/plugins.sh --install learnpress                                       # the builder, the tool, functions, args, AI items
bash core/scripts/plugins.sh --configure learnpress                                     # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an AI item you edited stays. The WordPress plugin
cannot be deactivated or uninstalled while this one is in use: take this one off first.

Everything the plugin carries lands in the folder it belongs to, when that folder is an active
workspace folder:

| What | Lands in |
| --- | --- |
| `cmd-learnpress-project.sh`, `cmd-tools-learnpress-courses.sh` | every active sites folder: `dev/`, `test/`, `sandboxes/`, `demos/` |
| The first feature of the courses, and the script that writes the sample courses, a tidy-up, a status and the counts | `core/scripts/plugins/learnpress/`, beside its functions |
| The agents `learnpress-site-builder`, `learnpress-tester` | `ai-agents/` |
| The skill `learnpress-scenarios` | `ai-skills/` |
| The command `/learnpress-test` | `ai-commands/` |
| The prompts `learnpress-build-and-test`, `learnpress-quiz-round` | `ai-prompts/` |

There they are listed like any other item of the folder, and installed into Claude Code from there.

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder, for the builder: `dev`, `test`, `sandboxes`, `demos` (`dev` is the one added when none is there). The folder also carries `cmd-tools-testing.sh` and the Users tools this plugin's hooks answer to.
- `wordpress`, the WordPress plugin: the site is made by its builder (`wordpress_build`), its testing hook runs first on a site of courses (the WordPress step pack, its users registry), and WP-CLI goes through its tool. `--with-needs` requires it from npm (`@webship.co/workspace-wordpress`), or from the folder beside this package when it was required from a path.
- `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`: the AI folders its agents, its skill, its command and its prompts are placed in.

`--require` says so, `--activate` and `--install` stop until the workspace has them, and `--with-needs` adds what is missing first:

```bash
bash core/scripts/plugins.sh --activate learnpress --with-needs   # dev, wordpress and the four AI folders are required, activated and installed first
bash core/scripts/plugins.sh --install learnpress
```

Everything the builder runs for a site runs in the site's own container, through the container tool the workspace already needs: WP-CLI is in the web container. The plugin asks for no command of its own on the machine.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-learnpress-project.sh` | The builder, in the Build list as **LearnPress (courses on WordPress)**, installed into every sites folder |
| `commands/cmd-tools-learnpress-courses.sh` | The courses' tool: what the courses hold, the default accounts, the sample courses, a tidy-up |
| `scripts/functions/fun-learnpress.sh` | The bash functions behind them, sourced by bootstrap once installed; the names the core's tools look for (`set_learnpress_users`, `add_learnpress_users`, `cancel_learnpress_users`, `testing_configure_learnpress`) |
| `scripts/args/arg-learnpress.sh`, `arg-learnpress-courses.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `scripts/learning-site.php` | The script the functions run in the site with WP-CLI: the sample courses, a tidy-up, a status and the counts, each through the plugin's own models (the step pack's own script) |
| `testing/courses.feature` | The first feature a site of courses gets when testing is set up |
| `ai/agents/learnpress-site-builder.md` | The agent that builds and maintains sites of courses with these commands |
| `ai/agents/learnpress-tester.md` | The agent that writes and runs scenarios with the courses' step pack |
| `ai/skills/learnpress-scenarios/` | The skill: the step pack's phrases by area, the traps found on a real site of courses, three example features |
| `ai/commands/learnpress-test.md` | The slash command `/learnpress-test <site>`: set up, match every step, run, report |
| `ai/prompts/learnpress-build-and-test.md`, `learnpress-quiz-round.md` | Two prompts: whole launch commands for a new session |
| `src/index.ts` | `register(api)`: what the assistant is told about LearnPress here |
| `features/learnpress.feature` | Scenarios for the dashboard's own browser suite |
| `features/learnpress-runtimes.feature` | The row, the test users and two pages of the courses of a site built on Docker Compose and on Kubernetes |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## The builder

Run it from a sites folder. `--help` is safe.

```bash
cd ~/workspace/dev
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course
```

| Flag | What it does |
| --- | --- |
| `--install` | Install WordPress with the workspace account as the administrator, set pretty addresses, then add LearnPress from the plugin directory and activate it: its activation makes its tables, its pages (Courses, Profile, Checkout, Instructors, Become an Instructor, Terms and Conditions) and its roles. Without it, WordPress is downloaded and LearnPress put in its plugins, to activate once the site is installed |
| `--add-users` | With `--install`: add the default accounts, one per place in the courses, each with its role on the site and the name the site shows |
| `--sample-course` | With `--install`: two free courses of the instructor, "Webship Testing Basics" (the sections "Getting started" with the lessons "What a scenario is" and "Steps and features", and "Check what you learned" with the quiz "Basics quiz" of three questions: true or false, one choice, several choices) and "Webship Advanced Testing" (the lesson "Tags and hooks"), and the student enrolled in the first |
| `--version <x>` | The LearnPress release (`latest` by default) |
| `--wordpress-version <x>` | The WordPress release (`latest` by default) |
| `--locale <x>` | The language WordPress is downloaded in |
| `--php-version <x>` | The PHP of the project container |
| `--runtime <name>` | The container runtime to build on: `ddev` (the default), `docker`, `kubernetes`, `podman`, `lando` or `docksal`. See [Runtimes](#runtimes) |
| `--launch` | Open the course list when it is ready |

On DDEV the courses answer at `https://mycourses.ddev.site/courses/` (a student's profile at `/profile/`), the
administration at `/wp-admin` (the menu "LearnPress"), the mail catcher at `https://mycourses.ddev.site:8026`. The
WordPress plugin's builder makes the project (of the type `wordpress`) and installs the site; the container tool writes
the database settings, the builder writes none. A project of the same name is deleted first.

Nothing paid and no account anywhere: the free plugin from the plugin directory, no add-on, the theme WordPress
installs with, and courses written by the plugin's own models.

### Runtimes

```bash
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course                        # DDEV, the default
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course --runtime docker       # Docker Compose
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course --runtime kubernetes   # a Kubernetes cluster
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course --runtime lando        # Lando
bash cmd-learnpress-project.sh mycourses --install --add-users --sample-course --runtime docksal      # Docksal
```

Without `--runtime` a build takes `container.runtime` of the workspace's `settings.yml`, then DDEV.
It needs a Webship Workspace with the container runtimes
([webship/workspace#694](https://github.com/webship/workspace/issues/694)); on an older one the
builder refuses `--runtime` and builds on DDEV only. Lando and Docksal need a Workspace whose runtime
layer has them ([webship/workspace#729](https://github.com/webship/workspace/issues/729),
[#730](https://github.com/webship/workspace/issues/730)).

| | DDEV | Docker Compose | Kubernetes | Podman | Lando | Docksal |
| --- | --- | --- | --- | --- | --- | --- |
| Build with `--install --add-users --sample-course` | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| The courses and the administration; a login as the workspace account and the default accounts | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| `cmd-tools-learnpress-courses.sh` (what the courses hold), and WP-CLI (`cmd-tools-wordpress-cli.sh`) | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| Test users, cancelled and added | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| Mail caught by Mailpit (WordPress's lost-password mail) | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| The testing setup and the first features | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| The step pack's examples, with the sample courses (13 scenarios) | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| Export and import the database | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |
| The row in the dashboard, and remove | Yes | Yes | Not yet run | Not yet run | Not yet run | Not yet run |

"Yes" means it was run on a real site of that runtime. A runtime "Not yet run" runs the same code (the WordPress
plugin's builder on that runtime, then the same WP-CLI calls) and was not run yet; Podman runs the same code as Docker
Compose.

| Runtime | The site's address | What the project carries |
| --- | --- | --- |
| DDEV | `https://mycourses.ddev.site` | `.ddev/config.yaml`, and the plugin's claim `.ddev/config.learnpress.yaml` |
| Docker Compose | `http://127.0.0.1:<port>`, printed by the build | `compose.yaml`, `.webship/runtime/Dockerfile` |
| Kubernetes | `http://<node address>:<port>`, printed by the build | The same, and `k8s/` (the namespace `ws-mycourses`) |
| Lando | `http://127.0.0.1:<port>`, printed by the build | `.lando.yml` (Lando's proxy stays off) |
| Docksal | `http://mycourses.docksal.site`, on Docksal's own proxy | `.docksal/docksal.env`, `.docksal/docksal.yml` |

What differs on Docker Compose, Kubernetes, Lando and Docksal:

- **The claim** is `platform: learnpress` in the `x-webship` block (the core's `rt_claim`): no `.ddev/` folder is written there, and the row's Tests menu offers the list of the courses by it.
- **The site** is the WordPress plugin's, built on the same runtime: its `wp-config.php` with the stack's database (`db`/`db`/`db` on the host `db`), the address it is asked on, and the `.htaccess` Apache needs.
- **Cancelling the test users** deletes them, as on DDEV (WordPress's user delete, with what was theirs): `--add-users`, then `cmd-tools-learnpress-courses.sh <site> --sample-course`, put them and the sample courses back.
- **HTTPS and a host name** are DDEV's: a runtime's address is plain HTTP.

The same commands work on every runtime: `cmd-tools-learnpress-courses.sh`, `cmd-tools-add-users.sh`,
`cmd-tools-testing.sh`. The pattern is the Workspace's
[`core/docs/plugins-on-runtimes.md`](https://github.com/webship/workspace/blob/1.0.x/core/docs/plugins-on-runtimes.md).

### The plugin's claim on the project

A site of courses is a project of the type `wordpress`, which is the WordPress plugin's. On DDEV the builder leaves
`.ddev/config.learnpress.yaml` in the project: a config overlay of the container tool with one key
(`web_environment: WEBSHIP_WORKSPACE_PLATFORM=learnpress`, in the web container's environment from its next start;
nothing of the site reads it). The file's name is what the workspace reads: a project that carries
`config.<plugin>.yaml` takes the test users of that plugin, so the row's Tests menu offers the list of the courses
(`learnpress`) instead of the WordPress one. On another runtime the claim is `platform: learnpress` in the `x-webship`
block (see [Runtimes](#runtimes)). A WordPress project that got the courses plugin another way (its folder in the
plugins) is a site of courses for the tools too.

### The courses' tool

The tool runs the plugin's `learning-site.php` with WP-CLI in the site's container for the sample courses, the
tidy-up, the status and the counts, which reads and writes with the plugin's own models (a course's sections and
items, a quiz's questions and their answers, an enrolment), so the counts the courses show are the ones the plugin
keeps.

```bash
bash cmd-tools-learnpress-courses.sh mycourses                   # the courses, each account's enrolments and progress
bash cmd-tools-learnpress-courses.sh mycourses --add-users       # the default accounts, with their roles and names
bash cmd-tools-learnpress-courses.sh mycourses --cancel-users    # delete them, with what was theirs
bash cmd-tools-learnpress-courses.sh mycourses --sample-course   # the sample courses; what is there is kept
bash cmd-tools-learnpress-courses.sh mycourses --tidy            # take away what a stopped test run left
```

The tidy-up deletes the learners' orders (a free enrolment records an order of $0.00, and moving it to the bin does
not end the enrolment), takes their enrolments, progress, quiz attempts and the plugin's history rows of them away
(LearnPress keeps a history row of every enrolment and attempt, which its own tools keep when they remove an
enrolment) and enrols the student in the first course again, deletes the courses, lessons, quizzes and questions named
"Webship test …" with their sections, and publishes the sample courses again (an instructor's published course waits
for review).

WP-CLI is the WordPress plugin's tool:

```bash
bash cmd-tools-wordpress-cli.sh mycourses --run "post list --post_type=lp_course"
bash cmd-tools-wordpress-cli.sh mycourses --run "plugin get learnpress --field=version"
```

### The default accounts

| Account | Address | Role on the site | Place in the courses | Handle in the tests |
| --- | --- | --- | --- | --- |
| `administrator` | `administrator@example.com` | administrator | Every course, the settings and the tools | `admin` |
| `instructor` | `instructor@example.com` | LearnPress's instructor (`lp_teacher`) | The sample courses are theirs; the course editor | `instructor` |
| `student` | `student@example.com` | subscriber | Enrolled in "Webship Testing Basics" | `student` |
| `student2` | `student2@example.com` | subscriber | Enrolled in nothing | `student2` |

One account per place in the courses, each named after it ("Student Test" on the site), with the password of the
workspace's other default lists. They are for local sites and for tests; a test suite logs in as them and never
creates or deletes one. An account of your own, and the workspace account, stay when the default accounts are added or
cancelled.

The row's Tests menu offers **Add the test users** and **Cancel the test users** for a site this plugin claims: they
run the same list as

```bash
bash cmd-tools-add-users.sh mycourses learnpress       # the core's tool, with the plugin's list
bash cmd-tools-cancel-users.sh mycourses learnpress
```

Adding them again gives each its role and its name back. Cancelling deletes the accounts with what was theirs: WordPress
deletes the instructor's courses, lessons, quizzes and questions, and the tool then takes away what the plugin's own
tables keep of them (the accounts' enrolments, progress, history rows and orders, the sections of the courses and their
items). `--add-users` then `--sample-course` bring the accounts and the sample courses back.

### Test a site of courses

```bash
bash cmd-tools-testing.sh mycourses                 # webship-js, both step packs, the users registry, the first features
bash cmd-tools-testing.sh mycourses --run           # run the suite in the container
bash cmd-tools-testing.sh mycourses --run --path tests/features/courses.feature
bash cmd-tools-testing.sh mycourses --list-steps    # the step packs the project has, in one profile
```

`cmd-tools-testing.sh` is the workspace's own. For a site of courses, this plugin's hook first runs the WordPress
plugin's (its pack, its users registry, `tests/features/site.feature`), then adds `@webship-js/learnpress-steps` to
`package.json` and its step definitions to `cucumber.js` in the same profile (the courses' pack is an extension of the
WordPress one and loads it itself), adds the tags that keep the pack's assertions that must fail out of a normal run,
the handles of the courses' accounts (with the names the site shows, by which a step tells which account is logged in;
overridable with `WP_<HANDLE>_USER` and `WP_<HANDLE>_PASSWORD`) in the users registry, and
`tests/features/courses.feature` (a course and its curriculum for a visitor, the enrolled student and its profile, a
student who is not enrolled, the courses and the course settings of the administration); it makes sure the default
accounts are on the site. It is idempotent: a second run adds what is missing and keeps what was changed.

## The AI items

`ai/` in the package holds one folder per kind, the manifest's `ai` block names each item, and
`--install` places it in the workspace folder of that kind.

| Kind | Item | Use it to |
| --- | --- | --- |
| Agent | `learnpress-site-builder` | Build, update, maintain or remove a site of courses with the builder, the courses' tool and the WP-CLI tool, in containers only, with nothing paid and no account anywhere |
| Agent | `learnpress-tester` | Set the testing stack up, look at the courses in the Playwright MCP browser first, write scenarios from the packs' steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |
| Skill | `learnpress-scenarios` | Write a scenario from phrases that exist: the packs' steps by area, the handles of the users registry, the traps found on a real site of courses, and three features that pass on a fresh site with the sample courses |
| Command | `/learnpress-test <site> [feature or @tag]` | Run the suite of a site from inside a session: set up when missing, match every step, run, report what failed and why |
| Prompt | `learnpress-build-and-test` | Start a session that builds a site of courses, says what it holds, sets the testing stack up and runs the first feature |
| Prompt | `learnpress-quiz-round` | Start a session that writes and runs the scenario of a round of a quiz: started, answered, finished, reviewed or retaken |

After `--install` each is in its folder on the dashboard. **Install** there puts an agent, a skill
or a command into Claude Code (`~/.claude/agents`, `~/.claude/skills`, `~/.claude/commands`), or
from the command line:

```bash
cd ~/workspace/ai-agents   && bash cmd-tools-ai-items.sh learnpress-tester --install
cd ~/workspace/ai-skills   && bash cmd-tools-ai-items.sh learnpress-scenarios --install
cd ~/workspace/ai-commands && bash cmd-tools-ai-items.sh learnpress-test --install
```

A prompt is not installed: it is the whole `claude …` launch command of a new session, and the
dashboard's **New screen** form lists it as a template. By hand, fill the placeholders in and run
the command of the file from the folder it names.

The items are written for any AI CLI, with Claude Code as the default shape: the frontmatter and
the file layout are Claude Code's, the body of each item is plain Markdown that names no tool or
feature of one CLI, a command says in words what its arguments are, and the text between the
triple quotes of a prompt can be given to another AI CLI as it is.

Every step phrase the items show is checked against the definitions of the courses' step pack, of the
WordPress pack it brings and of webship-js (`tests/fixtures/step-definitions.txt`), and every command
and flag against the plugin's own, the WordPress plugin's and the workspace's.

## What is tied to the container tool

The builder and the tools call the container tool with plain verbs only (`ddev wp …`, `ddev exec`,
`ddev start`, `ddev launch`): no container is reached by its name, and the tool's own project file is
not read. On DDEV two things are DDEV's by name: the claim file lives in the tool's folder
(`.ddev/config.learnpress.yaml`, the place the workspace looks for it), and the addresses the builder
prints (`https://<name>.ddev.site`, the mail catcher at port 8026) are the ones DDEV's router gives a
project. On another runtime the claim is in the `x-webship` block and the addresses are the runtime's
(`rt_url`, `rt_mail_url`).

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the builder, the AI items, the functions against a scaffolded project
```

CI runs the same on Node.js 24 and 26, parses every shell script, and runs the plugin's
`features/learnpress.feature` against a dashboard with this plugin (and the WordPress plugin it needs)
installed (`webship/workspace/.github/workflows/plugin-browser-suite.yml`).

When the step pack's release line changes, refresh the fixture from a project whose testing stack is
set up: `node <this plugin>/tests/fixtures/refresh-step-definitions.js > <this plugin>/tests/fixtures/step-definitions.txt`.
