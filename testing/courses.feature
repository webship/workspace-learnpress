Feature: The courses answer, and their accounts are in them
  As the owner of the site
  I want the course list, a course and each default account to work
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The accounts are the default ones (cmd-tools-learnpress-courses.sh --add-users); a scenario logs in by a handle of
  # the users registry in cucumber.js, so no password is written here. It passes on a site built with --install
  # --add-users --sample-course.

  @critical
  Scenario: A visitor finds a course and reads its curriculum
    Given I am an anonymous user
    When I go to the course list
    Then the course list should show "Webship Testing Basics"
    When I go to the course "Webship Testing Basics"
    Then the curriculum should show the section "Getting started" with "What a scenario is", "Steps and features"
    And the course page should offer "Start Now"

  Scenario: The enrolled student is offered to continue, and its profile counts the course
    Given I am a logged in user with the "student" user
    When I go to the course "Webship Testing Basics"
    Then the course page should offer "Continue"
    When I go to my courses
    Then my profile should count "Enrolled Course" as "1"
    And my profile should list "Webship Testing Basics"

  Scenario: A student who is not enrolled is offered to start
    Given I am a logged in user with the "student2" user
    When I go to the course "Webship Testing Basics"
    Then the course page should offer "Start Now"

  Scenario: The administrator reads the courses and their settings
    Given I am a logged in user with the "admin" user
    When I go to the "Courses" admin screen
    Then the administration should list the course "Webship Testing Basics" with "2 Sections 2 Lessons 1 Quiz"
    When I go to the "Course settings" admin screen
    Then the "Review courses" option should be on
