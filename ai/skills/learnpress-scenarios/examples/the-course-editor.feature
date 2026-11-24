Feature: The course editor of an instructor
  As an instructor
  I want to make a course with its sections, lessons and quiz
  So that students can learn it once the administrator has reviewed it

  # An example of the learnpress-scenarios skill. It passes on a site built with --install --add-users
  # --sample-course; the course, its lesson and its quiz are deleted for good when the scenario ends.

  Scenario: An instructor makes a course with a section, a lesson and a quiz, and sends it for review
    Given there is no course "Webship test course"
    And there is no lesson "Webship test lesson"
    And there is no quiz "Webship test quiz"
    And I am a logged in user with the "instructor" user
    When I start a new course "Webship test course"
    And I add the section "Webship test section" to the curriculum
    And I add the lesson "Webship test lesson" to the section "Webship test section"
    And I add the quiz "Webship test quiz" to the section "Webship test section"
    Then the curriculum should count "1 Section" and "2 Items"
    When I publish the course
    Then the course should be "Pending Review"

  Scenario: The administrator reads the courses and how a course is run
    Given I am a logged in user with the "admin" user
    When I go to the "Courses" admin screen
    Then the administration should list the course "Webship Testing Basics" with "2 Sections 2 Lessons 1 Quiz"
    And the administration should list the course "Webship Advanced Testing" with "Free"
    When I go to the "Course settings" admin screen
    Then the "Review courses" option should be on
    And the "Auto start" option should be on
