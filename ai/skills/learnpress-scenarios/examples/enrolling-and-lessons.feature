Feature: Enrolling and the lessons of a course
  As a student
  I want to enrol in a free course and work through its lessons
  So that I learn it one lesson at a time

  # An example of the learnpress-scenarios skill. It passes on a site built with --install --add-users
  # --sample-course; the enrolment, its order and the progress come back when each scenario ends.

  Scenario: A course page shows its curriculum, and a student who is not enrolled is offered to start
    Given I am a logged in user with the "student2" user
    When I go to the course "Webship Testing Basics"
    Then the curriculum should show the section "Getting started" with "What a scenario is", "Steps and features"
    And the instructor of the course should be "Instructor Test"
    And the course page should offer "Start Now"
    And the course page should not offer "Continue"

  Scenario: A student enrols in a free course and completes its first lesson
    Given I am a logged in user with the "student2" user
    When I start the course "Webship Testing Basics"
    Then the progress of the course should be "0 of 3 items"
    When I open "What a scenario is" in the course "Webship Testing Basics"
    And I complete the lesson
    Then the course should say "Congrats! You have completed “What a scenario is”."
    And the progress of the course should be "1 of 3 items"
    And the item "What a scenario is" should be completed

  Scenario: The enrolled student completes a lesson, and its profile counts the course
    Given I am a logged in user with the "student" user
    When I open "Steps and features" in the course "Webship Testing Basics"
    And I complete the lesson
    Then the item "Steps and features" should be completed
    When I go to my courses
    Then my profile should count "Enrolled Course" as "1"
    And my profile should list "Webship Testing Basics"
