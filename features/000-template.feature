# Template: copy to features/NNN-slug.feature, mirroring specs/NNN-slug.md.
# Conventions: docs/standards/specification-style.md §6. New scenarios stay @draft until approved.
@draft
Feature: Feature title
  One or two sentences on the user-visible capability.
  Specification: specs/NNN-slug.md

  Background:
    Given a defined initial state shared by all scenarios

  @SPEC-NNN-R1
  Rule: SPEC-NNN-R1 — short statement of the rule

    @SPEC-NNN-S01
    Scenario: Successful outcome in domain terms
      Given an initial observable state
      When one action or event occurs
      Then an observable outcome is produced

    @SPEC-NNN-S02
    Scenario Outline: Boundary values are handled
      Given a value of <value>
      When the action occurs
      Then the outcome is <outcome>

      Examples:
        | value | outcome  |
        | 0     | accepted |
        | -1    | rejected |
