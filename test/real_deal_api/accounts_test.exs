defmodule RealDealApi.AccountsTest do
  alias Ecto.UUID
  use RealDealApi.DataCase
  alias RealDealApi.{Accounts, Accounts.Account}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(RealDealApi.Repo)
  end

  describe "create_account/1" do
    test "success: it inserts an account in the db and returns the account" do
      params = Factory.string_params_for(:account)

      assert {:ok, %Account{} = returned_account} = Accounts.create_account(params)

      account_from_db = Repo.get(Account, returned_account.id)

      assert returned_account == account_from_db

      mutated = ["hash_password"]

      for {param_field, expected} <- params, param_field not in mutated do
        schema_field = String.to_existing_atom(param_field)
        actual = Map.get(account_from_db, schema_field)

        assert actual == expected,
               "Valuse did not match for field: #{param_field}\nexpected: #{inspect(expected)}\nactual: #{inspect(actual)}"
      end

      assert Bcrypt.verify_pass(params["hash_password"], returned_account.hash_password),
             "Password: #{inspect(params["hash_password"])} does not match \mhash: #{inspect(returned_account.hash_password)}"

      assert account_from_db.inserted_at == account_from_db.updated_at
    end

    test "error: returns an error tuple when account can't be created" do
      missing_params = %{}

      assert {:error, %Changeset{valid?: false}} = Accounts.create_account(missing_params)
    end
  end

  describe "get_account/1" do
    test "success: it returns an account when given a valid UUID" do
      existing_account = Factory.insert(:account)
      assert returned_account = Accounts.get_account!(existing_account.id)
      assert returned_account == existing_account
    end

    test "error: raises a Ecto.NoResultsError when an account doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_account!(Ecto.UUID.autogenerate())
      end
    end
  end
end
