class Locomotive::BasePresenter

  include Locomotive::Presentable

  include ActionView::Helpers::SanitizeHelper
  extend  ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  ## default properties ##
  property    :id, alias: :_id
  properties  :created_at, :updated_at, type: 'Date', only_getter: true

  ## utility accessors ##
  attr_reader :ability, :depth

  # Set the ability object to check if we can or not
  # get a property.
  #
  def after_initialize
    @depth    = self.options[:depth] || 0
    @ability  = self.options[:ability]

    if @options[:current_account] && @options[:current_site]
      @ability = Locomotive::Ability.new @options[:current_account], @options[:current_site]
    end
  end

  # Get the id of the source only if it has been persisted
  # or if it's an embedded document.
  #
  # @return [ String ] The id of the source, nil if not persisted or not embedded.
  #
  def id
    self.source.persisted? || self.source.embedded? ? self.source._id.to_s : nil
  end

  # Check if there is an ability object used for permissions.
  #
  # @return [ Boolean ] True if defined, false otherwise
  #
  def ability?
    self.ability.present?
  end

  # Shortcut to the site taken from the source.
  #
  # @return [ Object ] The site or nil if not found
  #
  def site
    self.source.try(:site)
  end

  # Shortcut to the errors of the source
  #
  # @return [ Hash ] The errors or an empty hash if no errors
  #
  def errors
    self.source.errors.to_hash.stringify_keys
  end

  # Return the set of setters with their options.
  #
  # @param [ Hash ] options Some options: with_ids (add id and _id)
  #
  # @return [ Hash ] The setters
  #
  def self.setters_to_hash(options = {})
    options = { without_ids: true }.merge(options)

    {}.tap do |hash|
      self.setters.each do |name|
        next if %w(id _id).include?(name.to_s) && options[:without_ids]
        hash[name] = self.getters_or_setters_to_hash(name)
      end
    end
  end

  # Return the set of getters with their options.
  #
  # @return [ Hash ] The getters
  #
  def self.getters_to_hash
    {}.tap do |hash|
      self.getters.each do |name|
        next if %w(created_at updated_at).include?(name)
        hash[name] = self.getters_or_setters_to_hash(name)
      end

      %w(created_at updated_at).each do |name|
        hash[name] = self.getters_or_setters_to_hash(name)
      end
    end
  end

  def self.getters_or_setters_to_hash(name)
    options   = self.property_options[name] || {}

    attributes = {
      type:         options[:type] || 'String',
      required:     options[:required].nil? ? true : options[:required],
      alias_of:     self.alias_of(name),
      description:  options[:description]
    }

    if options[:presenter]
      attributes[:collection_of] = {
        name:   options[:presenter].to_s.demodulize.gsub(/Presenter$/, '').underscore,
        params: options[:presenter].setters_to_hash
      }
    end

    attributes
  end

end
