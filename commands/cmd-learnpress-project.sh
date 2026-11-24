#!/usr/bin/env bash

# workspace-name: LearnPress (courses on WordPress)

# Installed by the LearnPress plugin (plugins.sh --install learnpress); __WORKSPACE__ is the workspace it was installed into.
#
# Build a site of courses in a container: the WordPress plugin's builder makes the site (the latest WordPress, or the
# one --wordpress-version names), then the free LearnPress plugin is added from the plugin directory, on DDEV by
# default or on the runtime --runtime names. With --install LearnPress is activated (its tables, its pages, its roles);
# with --add-users the default accounts, one per place in the courses; with --sample-course the courses, lessons, quiz
# and enrolment the step pack's features name. The courses' own tool is cmd-tools-learnpress-courses.sh; WP-CLI is
# the WordPress plugin's tool: bash cmd-tools-wordpress-cli.sh <name> --run "post list --post_type=lp_course".

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Set the versions: of LearnPress (--version) and of WordPress (--wordpress-version).
site_version="latest";
wordpress_version="latest";

# Distribution.
distribution_name="learnpress";
distribution_title="LearnPress";
distribution_webroot="";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} site of courses in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/learnpress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/learnpress/args/arg-learnpress.sh || exit 1 ;

shift $#;

learnpress_build ;
