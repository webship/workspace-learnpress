Feature: The quiz of a course
  As a student
  I want to take the quiz of a course, see my result and try again
  So that I know what I learned

  # An example of the learnpress-scenarios skill. It passes on a site built with --install --add-users
  # --sample-course; the quiz's attempts and results come back when each scenario ends.

  Scenario: A quiz answered right is passed, and its review shows the answers
    Given I am a logged in user with the "student" user
    When I start the quiz "Basics quiz" of the course "Webship Testing Basics"
    And I answer "True" to "A feature holds scenarios."
    And I answer "Given" to "Which keyword sets the scene of a scenario?"
    And I answer "Given", "When" and "Then" to "Which words start a step?"
    And I finish the quiz
    Then the quiz should be passed
    And the quiz result should show "Points" as "3 / 3"
    And the quiz should offer "Retake (2)"
    When I review the quiz
    Then the question "A feature holds scenarios." should show "True" as the right answer
    And the question "A feature holds scenarios." should show "True" as my answer

  Scenario: A quiz answered wrong is failed, and a retake starts it again
    Given I am a logged in user with the "student" user
    When I start the quiz "Basics quiz" of the course "Webship Testing Basics"
    And I answer "False" to "A feature holds scenarios."
    And I finish the quiz
    Then the quiz should be failed
    And the quiz result should show "Wrong" as "1"
    And the quiz result should show "Skipped" as "2"
    When I retake the quiz
    Then the quiz should offer "Finish Quiz"

  Scenario: The profile lists the quiz taken, with its result
    Given I am a logged in user with the "student" user
    When I start the quiz "Basics quiz" of the course "Webship Testing Basics"
    And I answer "True" to "A feature holds scenarios."
    And I answer "Given" to "Which keyword sets the scene of a scenario?"
    And I answer "Given", "When" and "Then" to "Which words start a step?"
    And I finish the quiz
    When I go to my courses
    And I open the "Quizzes" tab of my profile
    Then my profile should list "Basics quiz" with "Passed"
