defmodule Glific.Enums.Constants do
  @moduledoc """
  The Enums constant are where all enum values across our entire
  application should be defined. This is the source of truth for
  all enums
  """

  defmacro __using__(_opts) do
    quote do
      # standard first part of a tuple for many api calls
      @api_status_const [:ok, :error]

      # the status determines if we can send a message to the contact
      @contact_status_const [:blocked, :failed, :invalid, :processing, :valid]

      # the provider status determines if we can send a message to the contact
      @contact_provider_status_const [:none, :session, :session_and_hsm, :hsm]

      # the enums for the flow engine
      @flow_case_const [:has_any_word]

      @flow_router_const [:switch]

      @flow_action_type_const [
        :enter_flow,
        :send_msg,
        :set_contact_language,
        :wait_for_response,
        :set_contact_field
      ]

      ## We need to update the exiting value from message to messaging and then remove this enum.
      @flow_type_const [:message]

      # the direction of the messages: inbound: provider to glific, outbound: glific to provider
      @message_flow_const [:inbound, :outbound]

      # the status of the message as indicated by the provider
      @message_status_const [
        :sent,
        :delivered,
        :enqueued,
        :error,
        :read,
        :received,
        :contact_opt_out
      ]

      # the different possible types of message
      @message_type_const [
        :audio,
        :contact,
        :document,
        :hsm,
        :image,
        :location,
        :text,
        :video,
        :sticker
      ]

      # the possible question type constants
      @question_type_const [:text, :numeric, :date]

      # the possible sort direction for lists/rows, typically used in DB operations
      @sort_order_const [:asc, :desc]

      # Supported types for contact field values
      @contact_field_value_type_const [:text, :integer, :number, :boolean, :date]

      # Contact fields scope types
      @contact_field_scope_const [:contact, :globals]

      # User roles
      @user_roles_const [:none, :staff, :manager, :admin, :glific_admin]
    end
  end
end
