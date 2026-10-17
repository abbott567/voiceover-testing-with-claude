Feature: Sign-in page works with VoiceOver

  Background:
    Given VoiceOver is running
    And I am on "/sign-in"

  Scenario: The page has a sensible heading structure
    When I move through the page
    Then the first heading announced should include "heading level 1"
    And the first heading announced should include "Sign in"
    And no heading level should be skipped

  Scenario: Submitting an empty form moves focus to the error summary
    When I activate the "Sign in" button
    Then the announcement should include "There is a problem"
    And the error summary should list "Enter your email address"

  Scenario Outline: Each field is labelled and describes its own error
    When I activate the "Sign in" button
    And I move the VoiceOver cursor to the "<label>" field
    Then the announcement should include "<label>"
    And the announcement should include "Error: <error>"
    And the announcement should include "field"

    Examples:
      | label         | error                    |
      | Email address | Enter your email address |
      | Password      | Enter your password      |
