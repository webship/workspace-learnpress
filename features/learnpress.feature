Feature: The LearnPress plugin on the dashboard
  Once the plugin is activated and installed, with the WordPress plugin it needs, the sites folders offer the
  LearnPress builder, each AI folder lists the items of its kind the plugin ships, and the Settings page lists the
  plugin with its own page.

  # Settings lists every plugin that was added; the package and what the plugin ships are on its own page.
  Scenario: Settings lists the plugin, and its own page names its package and what it ships
    Given I am on "/settings"
     Then I should see "LearnPress"
     When I go to "/settings/plugin/learnpress"
     Then I should see "@webship.co/workspace-learnpress"
      And I should see "cmd-learnpress-project.sh"
      And I should see "cmd-tools-learnpress-courses.sh"
      And I should see "learnpress-site-builder"

  # The plugin builds on the WordPress plugin: activating it with what it needs brings that one too.
  Scenario: The WordPress plugin it needs is on Settings as well
    Given I am on "/settings/plugin/wordpress"
     Then I should see "@webship.co/workspace-wordpress"
      And I should see "cmd-wordpress-project.sh"

  Scenario: A sites folder offers the LearnPress builder next to the WordPress one
    Given I am on "/dev"
     Then "option[value='cmd-learnpress-project.sh']" should be attached
      And "option[value='cmd-wordpress-project.sh']" should be attached

  # The AI folders are searched by name: with every plugin on, a folder lists more than one page of items.
  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents?q=learnpress-"
     Then I should see "learnpress-site-builder"
      And I should see "learnpress-tester"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills?q=learnpress-scenarios"
     Then I should see "learnpress-scenarios"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands?q=learnpress-test"
     Then I should see "learnpress-test"

  Scenario: The AI Prompts folder lists the prompts the plugin ships
    Given I am on "/ai-prompts?q=learnpress-"
     Then I should see "learnpress-build-and-test"
      And I should see "learnpress-quiz-round"
