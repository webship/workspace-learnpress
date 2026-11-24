---
name: learnpress-scenarios
description: Write and run webship-js scenarios for a site of courses on WordPress with LearnPress of the Webship Workspace with the LearnPress step pack (`@webship-js/learnpress-steps`, which brings the WordPress step pack along) — the phrases by area (the course list and a course page, enrolling and lessons, quizzes, the student's profile, the instructor's course editor, the course settings), the accounts by handle, the traps found on a real site of courses, and three example features. Use when asked to "write a scenario for the courses", "test the quiz of <site>", or "which step checks a course's progress".
argument-hint: '<site> [what to cover]'
---

# learnpress-scenarios

Scenarios for a site of courses on WordPress with LearnPress of a Webship Workspace (`~/workspace`, container-based,
DDEV by default), written from the steps of [`@webship-js/learnpress-steps`](https://github.com/webship/learnpress-steps),
of the WordPress step pack it brings along and of [webship-js](https://github.com/webship/webship-js) itself, and run in
the site's container by the workspace's own command. It comes with the LearnPress plugin
(`@webship.co/workspace-learnpress`), like the builder (`cmd-learnpress-project.sh`), the courses' tool
(`cmd-tools-learnpress-courses.sh`) and the agents `learnpress-site-builder` and `learnpress-tester`.

## Where everything is

| What | Where |
| --- | --- |
| The site | `~/workspace/<folder>/<site>`, its courses at `https://<site>.ddev.site/courses/` (`<folder>` is a sites folder: `dev`, `test`, `sandboxes`, `demos`) |
| The suite's configuration | `<site>/cucumber.js`: the step definitions it loads, the users registry (`worldParameters.users`, with each account's `name`) |
| The features | `<site>/tests/features/*.feature` (`courses.feature` and `site.feature` are the first ones the setup wrote) |
| The courses' steps | `<site>/node_modules/@webship-js/learnpress-steps/tests/step-definitions/*.steps.js` |
| The site's steps (login, administration) | `<site>/node_modules/@webship-js/wordpress-steps/tests/step-definitions/*.steps.js` |
| webship-js's steps | `<site>/node_modules/webship-js/tests/step-definitions/*.js` |
| The reports | `<site>/tests/reports/` |

## The order of work

1. **Make sure the testing stack is there.** From the sites folder:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site>
   ```
   It adds webship-js, both step packs (in one profile: the courses' pack extends the WordPress one), the users
   registry with the handles of the courses' accounts, `tests/features/site.feature` and
   `tests/features/courses.feature`, and makes sure the default accounts are on the site. It is safe to run again: it
   adds what is missing and keeps what was changed.
2. **Read the installed steps before writing a phrase.** They are the source of truth: the packs move, and a phrase
   from memory is a guess.
   ```bash
   cd ~/workspace/<folder>/<site>
   grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/learnpress-steps/tests/step-definitions/*.steps.js
   ```
   Every step carries a comment block with five examples above it; open the file when a phrase is not obvious.
3. **Look at the page first** (the Playwright MCP browser, a tab of your own) when the scenario is about a page you
   have not seen.
4. **Write the feature** in `<site>/tests/features/`, from phrases that exist (the lists below).
5. **Match every step without a browser**, then run the feature, then the suite:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --tags "@critical"
   bash cmd-tools-testing.sh <site> --run
   ```
   A dry run says `Undefined` for a phrase no definition matches: fix the phrase, do not write a step for it.

## Accounts: a handle, never a password

```gherkin
Feature: Accounts
  Scenario: The student finds its course on its profile
    Given I am a logged in user with the "student" user
    When I go to my courses
    Then my profile should list "Webship Testing Basics"
```

The handles of the default accounts: `admin` (the site's `administrator`), `instructor`, `student` (enrolled in
"Webship Testing Basics") and `student2` (enrolled in nothing); each shows as "<Login> Test". A visitor is `Given I am
an anonymous user`. Never create an account in a scenario, and never log in as the workspace account.

## The phrases, by area

The course list and a course page:

```gherkin
When I go to the course list
Then the course list should show "Webship Testing Basics"
Then the course list should not show "Webship test course"
Then the course list should show "Webship Advanced Testing", "Webship Testing Basics" in this order
Then the course "Webship Testing Basics" of the list should read "by Instructor Test"
Then the course "Webship Advanced Testing" of the list should read "Free"
When I search the courses for "Advanced"
When I order the courses by "Title z-a"
When I go to the course "Webship Testing Basics"
Then the curriculum should show the section "Getting started" with "What a scenario is", "Steps and features"
Then the course should show "Quiz" as "1 Quiz"
Then the instructor of the course should be "Instructor Test"
Then the course page should offer "Start Now"
Then the course page should not offer "Continue"
```

Enrolling and lessons:

```gherkin
When I start the course "Webship Testing Basics"
When I open "What a scenario is" in the course "Webship Testing Basics"
When I complete the lesson
Then the course should say "Congrats! You have completed “What a scenario is”."
Then the progress of the course should be "1 of 3 items"
Then the item "What a scenario is" should be completed
Then the item "Basics quiz" should be locked
```

Quizzes:

```gherkin
When I start the quiz "Basics quiz" of the course "Webship Testing Basics"
When I answer "True" to "A feature holds scenarios."
When I answer "Given", "When" and "Then" to "Which words start a step?"
When I finish the quiz
Then the quiz should be passed
Then the quiz should be failed
Then the quiz result should show "Points" as "3 / 3"
Then the quiz result should show "Skipped" as "2"
When I review the quiz
When I go back to the result of the quiz
Then the question "A feature holds scenarios." should show "True" as the right answer
Then the question "A feature holds scenarios." should show "True" as my answer
When I retake the quiz
Then the quiz should offer "Retake (2)"
Then the quiz should not offer "Review"
```

The student's profile:

```gherkin
When I go to my courses
When I open the "Quizzes" tab of my profile
Then my profile should count "Enrolled Course" as "1"
Then my profile should list "Webship Testing Basics" with "0%"
Then my profile should not list "Webship Advanced Testing"
```

The instructor's course editor:

```gherkin
Given there is no course "Webship test course"
Given there is no lesson "Webship test lesson"
When I start a new course "Webship test course"
When I add the section "Webship test section" to the curriculum
When I add the lesson "Webship test lesson" to the section "Webship test section"
When I add the quiz "Webship test quiz" to the section "Webship test section"
Then the curriculum should count "1 Section" and "2 Items"
When I publish the course
Then the course should be "Pending Review"
```

The administration, read only (the screens by their names, with the WordPress pack's step):

```gherkin
When I go to the "Courses" admin screen
Then the administration should list the course "Webship Testing Basics" with "2 Sections 2 Lessons 1 Quiz"
When I go to the "Course settings" admin screen
Then the "Review courses" option should be on
Then the "Courses per page" option should be "8"
```

The screens a scenario opens by name: "Courses", "Lessons", "Quizzes", "Questions", "Orders", "Students", "Course
settings" and "Learning settings".

## Three example features

`examples/` beside this file holds three features that pass on a fresh site built with `--install --add-users
--sample-course`; copy one into `<site>/tests/features/` to start from it:

- `examples/enrolling-and-lessons.feature`: a course page for a student who is not enrolled, a free course started
  and its first lesson completed, the progress, the enrolled student's lesson and profile.
- `examples/the-quiz.feature`: a quiz passed and its review, a quiz failed and retaken, the profile's quizzes tab.
- `examples/the-course-editor.feature`: a course made by the instructor with a section, a lesson and a quiz and sent
  for review; the courses and the course settings of the administration.

## Traps found on a real site of courses

- **A free enrolment records an order.** "Start Now" on a free course makes an order of $0.00, "Completed". Moving it
  to the bin does not end the enrolment: the steps put the enrolment back with the plugin's own tools and delete the
  order for good.
- **Opening a lesson records progress.** An enrolled account that only opens a lesson has an item "in progress" on
  its course; the steps take it away when the scenario ends.
- **The plugin keeps a history.** Every enrolment and every attempt writes a history row, which the plugin's own
  "Assign" and "Unassign" keep; the steps remove it with the plugin's "Reset course progress" when every learner of
  the course is an account of the users registry, and say so when one is not: give a course of the suite no other
  learner.
- **The plugin asks first.** Completing a lesson, finishing a quiz and starting a retake each open a question ("Are
  you sure?"), in one of two kinds of box; the steps answer yes and wait for the page that follows.
- **The quiz fills by script.** Its questions come after the page loaded, a page at a time ("#page-2"); the steps find
  a question on whichever page it is and wait for the quiz's own state (started, completed).
- **An instructor's course waits for review.** With "Review courses" on (the default), the instructor's "Publish"
  leaves the course "Pending Review"; the administrator publishes it.
- **The curriculum editor is drawn by script**, with its own inputs for a section and an item; the counts ("1
  Section", "2 Items") are its heading.
- **The profile's tabs fill by script**: the steps wait for the tab's list, not only for its link.

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
- **For LearnPress.** Start with `ch06-form-testing-recipes.md` (a quiz's answers and the course editor),
  `ch07-waiting-dynamic-content.md` (the quiz, the profile's tabs and the curriculum filled by script),
  `ch08-modal-dialog-testing.md` (the plugin's questions before a lesson is completed, a quiz finished or retaken)
  and `ch21-when-tests-go-bad.md` (flaky, brittle and slow scenarios).
