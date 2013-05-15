module Spree::Chimpy
  class Subscription
    def initialize(model)
      @model      = model
      @changes    = model.changes.dup
      @interface  = Config.list
    end

    def subscribe
      Spree::Chimpy.fire_event(:subscribe, model: @model) if allowed?
    end

    def unsubscribe
      Spree::Chimpy.fire_event(:unsubscribe, model: @model) if allowed?
    end

    def resubscribe(&block)
      block.call if block

      return unless configured?

      if unsubscribing?
        @interface.unsubscribe(@model.email)
      elsif subscribing? || merge_vars_changed?
        subscribe
      end
    end

  private
    def configured?
      Config.configured?
    end

    def allowed?
      configured? && @model.subscribed
    end

    def subscribing?
      merge_vars_changed? && @model.subscribed
    end

    def unsubscribing?
      !@new_record && !@model.subscribed && @model.subscribed_changed?
    end

    def merge_vars_changed?
      Config.preferred_merge_vars.values.any? do |attr|
        @model.send("#{attr}_changed?")
      end
    end

    def merge_vars
      array = Config.preferred_merge_vars.except('EMAIL').map do |tag, method|
        [tag, @model.send(method).to_s]
      end

      Hash[array]
    end
  end
end
