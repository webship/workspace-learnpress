#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: a site of this folder that has LearnPress.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Add the default accounts, one per place in the courses: administrator, instructor, student and student2. An account that is there keeps its password and gets its role and its name back.')
parser.add_argument('-c', '--cancel-users',
                    action='store_true',
                    default=False,
                    help='Delete the default accounts, with their courses, enrolments, progress and history; --add-users then --sample-course bring them back.')
parser.add_argument('-s', '--sample-course',
                    action='store_true',
                    default=False,
                    help='Add the courses the test scenarios name (what is there already is kept): two free courses of the instructor, their lessons, a quiz, the student enrolled in the first.')
parser.add_argument('-t', '--tidy',
                    action='store_true',
                    default=False,
                    help='Take away what a stopped test run left (the orders, enrolments, progress, quiz attempts and history of the learners, the courses, lessons and quizzes named "Webship test …"), and enrol the student in the first course again.')
ARGEOF
