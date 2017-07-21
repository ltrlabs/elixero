defmodule EliXero.CoreApi.Models.Contacts.Contact.ContactPerson do
    use Ecto.Schema
    @derive {Poison.Encoder, except: [:__meta__]}

    schema "contactpersons" do
        field :ContactPersonID, Ecto.UUID
        field :FirstName, :string
        field :LastName, :string
        field :EmailAddress, :string
        field :IncludeInEmails, :boolean
        embeds_many :ValidationErrors, EliXero.CoreApi.Models.Common.Error
        embeds_many :Warnings, EliXero.CoreApi.Models.Common.Warning
        field :StatusAttributeString, :string
    end
end