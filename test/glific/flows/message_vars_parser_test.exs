defmodule Glific.Flows.MessageVarParserTest do
  use Glific.DataCase, async: true

  alias Glific.Contacts
  alias Glific.Flows.MessageVarParser

  test "parse/2 will parse the string with variable", attrs do
    # binding with 1 dots will replace the variable
    assert "hello Glific" ==
             MessageVarParser.parse("hello @contact.name", %{"contact" => %{"name" => "Glific"}})

    assert "hello Glific" ==
             MessageVarParser.parse("hello @contact.name.", %{"contact" => %{"name" => "Glific"}})

    assert "hello Glific" ==
             MessageVarParser.parse("hello @organization.name", %{
               "organization" => %{"name" => "Glific"}
             })

    # binding with 2 or 2 dots will replace the variable
    parsed_test =
      MessageVarParser.parse("hello @contact.fields.name", %{
        "contact" => %{"fields" => %{"name" => "Glific"}}
      })

    assert parsed_test == "hello Glific"

    parsed_test =
      MessageVarParser.parse("hello @contact.fields.name.category", %{
        "contact" => %{"fields" => %{"name" => %{"category" => "Glific"}}}
      })

    assert parsed_test == "hello Glific"

    # if variable is not defined then it won't effect the input
    parsed_test =
      MessageVarParser.parse("hello @contact.fields.name", %{
        "results" => %{"fields" => %{"name" => "Glific"}}
      })

    assert parsed_test == "hello @contact.fields.name"

    # atom keys will be convert into string automatically
    parsed_test = MessageVarParser.parse("hello @contact.name", %{"contact" => %{name: "Glific"}})

    assert parsed_test == "hello Glific"

    [contact | _tail] = Contacts.list_contacts(%{filter: attrs})
    contact = Map.from_struct(contact)
    parsed_test = MessageVarParser.parse("hello @contact.name", %{"contact" => contact})
    assert parsed_test == "hello #{contact.name}"

    [contact | _tail] = Contacts.list_contacts(%{filter: attrs})

    {:ok, contact} =
      Contacts.update_contact(contact, %{
        fields: %{
          "name" => %{
            "type" => "string",
            "value" => "Glific Contact",
            "inserted_at" => "2020-08-04"
          },
          "age" => %{
            "type" => "string",
            "value" => "20",
            "inserted_at" => "2020-08-04"
          }
        }
      })

    contact = Map.from_struct(contact)

    parsed_test =
      MessageVarParser.parse(
        "hello @contact.fields.name, your age is @contact.fields.age years.",
        %{"contact" => contact}
      )

    assert parsed_test == "hello Glific Contact, your age is 20 years."

    ## for contact groups
    conatct_fields = Contacts.get_contact_field_map(contact.id)
    assert MessageVarParser.parse("@contact.in_groups", %{"contact" => conatct_fields}) == "[]"
    assert MessageVarParser.parse("Hello world", nil) == "Hello world"
    assert MessageVarParser.parse("Hello world", %{}) == "Hello world"

    ## Parse all the keys and values in a map
    assert MessageVarParser.parse_map("ABC", nil) == "ABC"

    map =
      MessageVarParser.parse_map(%{"key" => "@contact.name"}, %{"contact" => %{"name" => "ABC"}})

    assert Map.get(map, "key") == "ABC"

    ## Parse all the results
    assert MessageVarParser.parse_results("@contact.name", nil) == "@contact.name"

    MessageVarParser.parse(
      "hello @contact.fields.name, your age is @contact.fields.age years.",
      %{"contact" => contact}
    )

    assert MessageVarParser.parse(
             "hello @results.name",
             %{"results" => %{"name" => %{"input" => "Jatin"}}}
           ) == "hello Jatin"

    assert MessageVarParser.parse(
             "hello @results.name.input",
             %{"results" => %{"name" => %{"input" => "Jatin"}}}
           ) == "hello Jatin"

    assert MessageVarParser.parse(
             "hello @results.parent.name",
             %{"results" => %{"parent" => %{"name" => %{"input" => "Jatin"}}}}
           ) == "hello Jatin"

    assert MessageVarParser.parse(
             "hello @results.parent.name.input",
             %{"results" => %{"parent" => %{"name" => %{"input" => "Jatin"}}}}
           ) == "hello Jatin"

    assert MessageVarParser.parse(
             "hello @results.child.name",
             %{"results" => %{"child" => %{"name" => %{"input" => "Jatin"}}}}
           ) == "hello Jatin"

    assert MessageVarParser.parse(
             "hello @results.child.name.input",
             %{"results" => %{"child" => %{"name" => %{"input" => "Jatin"}}, "parent" => %{}}}
           ) == "hello Jatin"
  end
end
