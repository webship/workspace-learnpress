#!/usr/bin/env bash

# Installed by the LearnPress plugin (plugins.sh --install learnpress); __WORKSPACE__ is the workspace it was installed into.
#
# The courses of one site of this workspace, in the project's web container: say what they hold (the courses and each
# account's enrolments and progress), add or cancel the default accounts, add the sample courses, take away what a
# stopped test run left. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="learnpress";

ARGPARSE_DESCRIPTION="The courses of a site of __WORKSPACE__: what they hold, the default accounts, the sample courses, a tidy-up"
# The args file comes with the plugin: core/scripts/plugins/learnpress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/learnpress/args/arg-learnpress-courses.sh || exit 1 ;

shift $#;

learnpress_courses_tool ;
