#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: its folder, and its name on the container runtime (on DDEV its host name too).')
parser.add_argument('--runtime',
                    dest='RUNTIME',
                    default="_none_",
                    choices=['ddev', 'docker', 'podman', 'kubernetes', 'lando', 'docksal'],
                    help='The container runtime to build on: ddev (the default, or container.runtime of settings.yml), docker (Docker Compose), podman, kubernetes, lando or docksal.')
parser.add_argument('-v', '--version',
                    default="${site_version}",
                    help='The LearnPress release to add, from the plugin directory: latest, or a version number. Example: --version 4.5.0 [default %(default)s]')
parser.add_argument('-w', '--wordpress-version',
                    default="${wordpress_version}",
                    help='The WordPress release to download: latest, nightly, or a version number. Example: --wordpress-version 7.1.5 [default %(default)s]')
parser.add_argument('-i', '--install',
                    action='store_true',
                    default=False,
                    help='Install WordPress with the workspace account as the administrator, and add LearnPress: its activation makes its tables, its pages (Courses, Profile, Checkout, Instructors) and its roles.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='With --install, add the default accounts, one per place in the courses: administrator, instructor, student and student2, the ones the test scenarios log in as.')
parser.add_argument('-s', '--sample-course',
                    action='store_true',
                    default=False,
                    help='With --install, add the courses the test scenarios name: two free courses of the instructor, their sections and lessons, a quiz with three questions, and the student enrolled in the first.')
parser.add_argument('-l', '--launch',
                    action='store_true',
                    default=False,
                    help='Open the course list in a browser when it is ready.')
parser.add_argument('--locale',
                    default="en_US",
                    help='The language WordPress is downloaded in. Example: --locale ar [default %(default)s]')
parser.add_argument('--php-version',
                    default="",
                    choices=['8.5', '8.4', '8.3', '8.2'],
                    help='PHP version for the project container; empty means the default of the container tool. Example: --php-version 8.4')
ARGEOF
