defmodule Ash.Resource.Validation.Builtins do
  @moduledoc """
  Built in validations that are available to all resources

  The functions in this module are imported by default in the validations section.
  """

  alias Ash.Resource.Validation

  @doc """
  Validates that an attribute's value is in a given list

  ## Examples

      validate one_of(:status, [:closed_won, :closed_lost])
  """
  @spec one_of(attribute :: atom, list(any)) :: Validation.ref()
  def one_of(attribute, values) do
    {Validation.OneOf, attribute: attribute, values: values}
  end

  @doc """
  Validates that an attribute or relationship is being changed

  ## Examples

      validate changing(:first_name)
      validate changing(:comments)
      validate changing(:comments, touching?: true)

  ## Options

  #{Ash.Resource.Validation.Changing.Opts.docs()}
  """
  @spec changing(attribute_or_relationship :: atom, opts :: Keyword.t()) :: Validation.ref()
  def changing(field, opts \\ []) do
    {Validation.Changing, Keyword.merge(opts, field: field)}
  end

  @doc """
  Validates that a field or argument matches another field or argument

  ## Examples

      validate confirm(:password, :password_confirmation)
      validate confirm(:email, :email_confirmation)
  """
  @spec confirm(attribute_or_argument :: atom, confirmation_attribute_or_argument :: atom) ::
          Validation.ref()
  def confirm(field, confirmation) do
    {Validation.Confirm, [field: field, confirmation: confirmation]}
  end

  @doc """
  Validates that an attribute is not being changed to a specific value, or does not equal the given value if it is not being changed.

  ## Examples

      validate attribute_does_not_equal(:admin, true)

      # Or to only check for changing to a given value
      validate attribute_does_not_equal(:admin, true), where: [changing(:admin)]
  """
  @spec attribute_does_not_equal(attribute :: atom, value :: term) :: Validation.ref()
  def attribute_does_not_equal(attribute, value) do
    {Validation.AttributeDoesNotEqual, attribute: attribute, value: value}
  end

  @doc """
  Validates that other validation does not pass

  ## Examples

      validate negate(one_of(:status, [:closed, :finished]))
  """
  @spec negate(validation :: Validation.ref()) :: Validation.ref()
  def negate(validation) do
    {Validation.Negate, validation: validation}
  end

  @doc """
  Validates that the action name matches the provided action name or names. Primarily meant for use in `where`.

  ## Examples

      validate present(:foo), where: [action_is(:bar)]

      validate present(:foo), where: action_is([:bar, :baz])
  """
  @spec action_is(action :: atom | list(atom)) :: Validation.ref()
  def action_is(action) do
    {Validation.ActionIs, action: action}
  end

  @doc """
  Validates that an attribute is being changed to a specific value, or equals the given value if it is not being changed.

  ## Examples

      validate attribute_equals(:admin, true)

      # Or to only check for changing to a given value
      validate attribute_equals(:admin, true), where: [changing(:admin)]
  """
  @spec attribute_equals(attribute :: atom, value :: term) :: Validation.ref()
  def attribute_equals(attribute, value) do
    {Validation.AttributeEquals, attribute: attribute, value: value}
  end

  @doc """
  Validates that an attribute is being changed to one of a set of specific values, or is in the the given list if it is not being changed.

  ## Examples

      validate attribute_in(:state, [1, 2, 3])

      # Or to only check for changing to a something in a given list
      validate attribute_in(:state, [1, 2, 3]), where: [changing(:state)]
  """
  @spec attribute_in(attribute :: atom, list :: [term]) :: Validation.ref()
  def attribute_in(attribute, list) do
    {Validation.AttributeIn, attribute: attribute, list: list}
  end

  @doc """
  Validates that an attribute on the original record meets the given length criteria

  ## Options

  #{Spark.Options.docs(Ash.Resource.Validation.StringLength.opt_schema())}

  ## Examples

      validate string_length(:slug, exact: 8)
      validate string_length(:password, min: 6)
      validate string_length(:secret, min: 4, max: 12)
  """
  @spec string_length(attribute :: atom, opts :: Keyword.t()) :: Validation.ref()
  def string_length(attribute, opts \\ []) do
    {Validation.StringLength, Keyword.merge(opts, attribute: attribute)}
  end

  @numericality_docs """
  Validates that an attribute or argument meets the given comparison criteria.

  The values provided for each option may be a literal value, attribute, argument, or a zero argument function.

  ## Options
  #{Spark.Options.docs(Ash.Resource.Validation.Compare.opt_schema())}

  ## Examples

      validate numericality(:age, greater_than_or_equal_to: 18),
        where: [attribute_equals(:show_adult_content, true)],
        message: "must be over %{greater_than_or_equal_to} to enable adult content."

      validate numericality(:points, greater_than: 0, less_than_or_equal_to: 100)
  """
  @doc @numericality_docs
  @spec numericality(attribute :: atom, opts :: Keyword.t()) :: Validation.ref()
  def numericality(attribute, opts \\ []) do
    compare(attribute, opts)
  end

  @doc String.replace(@numericality_docs, "numericality(", "compare(")
  @spec compare(attribute :: atom, opts :: Keyword.t()) :: Validation.ref()
  def compare(attribute, opts \\ []) do
    {Validation.Compare, Keyword.merge(opts, attribute: attribute)}
  end

  @doc """
  Validates that an attribute's value matches a given regex.

  `String.match?/2` is used to determine if the value matches.

  ## Examples

      validate match(:slug, "^[0-9a-z-_]+$")
  """
  @spec match(attribute :: atom, match :: Regex.t()) :: Validation.ref()
  def match(attribute, match) do
    {Validation.Match,
     attribute: attribute, match: match, message: "must match #{inspect(match)}"}
  end

  @doc """
  Validates that the given attribute or argument or list of attributes or arguments are not `nil`.

  Use options to specify how many must not be `nil`. If no options are provided, validates that they are all present.

  Keep in mind that some types cast certain values to `nil`, and validations are
  applied after all inputs have been cast. For example, a `:string` type attribute
  with the default constraints will cast `""` as `nil`, meaning an input of
  `""` would fail the `present` validation.

  ## Options

  #{Spark.Options.docs(Ash.Resource.Validation.Present.opt_schema())}

  ## Examples

      validate present(:name)

      validate present([:first_name, :last_name]), where: [absent(:full_name)]

      validate present([:is_admin, :is_normal_user], at_most: 1)
  """
  @spec present(attributes_or_arguments :: atom | list(atom), opts :: Keyword.t()) ::
          Validation.ref()
  def present(attributes, opts \\ []) do
    if opts == [] do
      attributes = List.wrap(attributes)
      {Validation.Present, attributes: attributes, exactly: Enum.count(attributes)}
    else
      opts = Keyword.put(opts, :attributes, List.wrap(attributes))
      {Validation.Present, opts}
    end
  end

  @doc """
  Validates that the attribute or list of attributes are not `nil`. See `present/2` for more information.

  ## Options

  #{Spark.Options.docs(Ash.Resource.Validation.AttributesPresent.opt_schema())}
  """
  @spec attributes_present(attributes :: atom | list(atom), opts :: Keyword.t()) ::
          Validation.ref()
  def attributes_present(attributes, opts \\ []) do
    if opts == [] do
      attributes = List.wrap(attributes)
      {Validation.AttributesPresent, attributes: attributes, exactly: Enum.count(attributes)}
    else
      opts = Keyword.put(opts, :attributes, List.wrap(attributes))
      {Validation.AttributesPresent, opts}
    end
  end

  @doc """
  Validates that the given attribute or argument or list of attributes or arguments are `nil`.

  This is the inverse of `present/2`.

  Use options to specify how many must be `nil`. If no options are provided, validates that they are all absent.

  Keep in mind that some types cast certain values to `nil`, and validations are
  applied after all inputs have been cast. For example, a `:string` type attribute
  with the default constraints will cast `""` as `nil`, meaning an input of
  `""` would pass the `absent` validation.

  ## Options

  #{String.replace(Spark.Options.docs(Ash.Resource.Validation.Present.opt_schema()), "present", "absent")}

  ## Examples

      validate absent(:unsettable_option)

      validate absent([:first_name, :last_name]), where: [present(:full_name)]

      validate absent([:is_admin, :is_normal_user], at_least: 1)
  """
  @spec absent(attributes_or_arguments :: atom | list(atom), opts :: Keyword.t()) ::
          Validation.ref()
  def absent(attributes, opts \\ []) do
    if opts == [] do
      {Validation.Present, attributes: List.wrap(attributes), exactly: 0}
    else
      attributes = List.wrap(attributes)
      count = Enum.count(attributes)

      new_opts =
        case Keyword.fetch(opts, :at_least) do
          {:ok, value} ->
            Keyword.put(opts, :at_most, count - value)

          :error ->
            Keyword.put(opts, :at_most, 0)
        end

      new_opts =
        case Keyword.fetch(opts, :at_most) do
          {:ok, value} ->
            Keyword.put(new_opts, :at_least, count - value)

          :error ->
            Keyword.put(new_opts, :at_least, 0)
        end

      present(attributes, new_opts)
    end
  end

  @doc """
  Validates that the attribute or list of attributes are `nil`. See `absent/2` for more information.

  ## Options

  #{String.replace(Spark.Options.docs(Ash.Resource.Validation.AttributesPresent.opt_schema()), "present", "absent")}
  """
  @spec attributes_absent(attributes :: atom | list(atom), opts :: Keyword.t()) ::
          Validation.ref()
  def attributes_absent(attributes, opts \\ []) do
    if opts == [] do
      {Validation.AttributesPresent, attributes: List.wrap(attributes), exactly: 0}
    else
      attributes = List.wrap(attributes)
      count = Enum.count(attributes)

      new_opts =
        case Keyword.fetch(opts, :at_least) do
          {:ok, value} ->
            Keyword.put(opts, :at_most, count - value)

          :error ->
            Keyword.put(opts, :at_most, 0)
        end

      new_opts =
        case Keyword.fetch(opts, :at_most) do
          {:ok, value} ->
            Keyword.put(new_opts, :at_least, count - value)

          :error ->
            Keyword.put(new_opts, :at_least, 0)
        end

      attributes_present(attributes, new_opts)
    end
  end

  @doc """
  Validates that an argument is not being changed to a specific value, or does not equal the given value if it is not being changed.

  ## Examples

      validate argument_does_not_equal(:admin, true)

      # Or to only check for changing to a given value
      validate argument_does_not_equal(:admin, true), where: [changing(:admin)]
  """
  @spec argument_does_not_equal(argument :: atom, value :: term) :: Validation.ref()
  def argument_does_not_equal(argument, value) do
    {Validation.ArgumentDoesNotEqual, argument: argument, value: value}
  end

  @doc """
  Validates that an argument is being changed to a specific value, or equals the given value if it is not being changed.

  ## Examples

      validate argument_equals(:admin, true)

      # Or to only check for changing to a given value
      validate argument_equals(:admin, true), where: [changing(:admin)]
  """
  @spec argument_equals(argument :: atom, value :: term) :: Validation.ref()
  def argument_equals(argument, value) do
    {Validation.ArgumentEquals, argument: argument, value: value}
  end

  @doc """
  Validates that an argument is being changed to one of a set of specific values, or is in the the given list if it is not being changed.

  ## Examples

      validate argument_in(:state, [1, 2, 3])

      # Or to only check for changing to a something in a given list
      validate argument_in(:state, [1, 2, 3]), where: [changing(:state)]
  """
  @spec argument_in(argument :: atom, list :: [term]) :: Validation.ref()
  def argument_in(argument, list) do
    {Validation.ArgumentIn, argument: argument, list: list}
  end
end
