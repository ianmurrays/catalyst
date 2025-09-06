# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "Test action"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  describe "#set_locale" do
    context "when user is authenticated" do
      let(:user) { User.create!(auth0_sub: "auth0|123", display_name: "Test User", email: "test@example.com") }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "when user has language preference" do
        before do
          user.preferences = { "language" => "es" }
          user.save!
        end

        it "sets locale to user's preference" do
          get :index
          expect(I18n.locale).to eq(:es)
        end
      end

      context "when user has no language preference" do
        before do
          user.preferences = {}
          user.save!
        end

        it "falls back to session locale if available" do
          session[:locale] = "da"
          get :index
          expect(I18n.locale).to eq(:da)
        end

        it "falls back to Accept-Language header if no session" do
          request.headers["Accept-Language"] = "es-ES,es;q=0.9,en;q=0.8"
          get :index
          expect(I18n.locale).to eq(:es)
        end

        it "falls back to default locale if nothing else available" do
          get :index
          expect(I18n.locale).to eq(:en)
        end
      end

      context "when user has invalid language preference" do
        before do
          user.preferences = { "language" => "invalid" }
          user.save(validate: false) # Skip validation for this test scenario
        end

        it "falls back to default locale" do
          get :index
          expect(I18n.locale).to eq(:en)
        end
      end
    end

    context "when user is not authenticated" do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it "uses session locale if available and valid" do
        session[:locale] = "es"
        get :index
        expect(I18n.locale).to eq(:es)
      end

      it "ignores session locale if invalid" do
        session[:locale] = "invalid"
        get :index
        expect(I18n.locale).to eq(:en)
      end

      it "uses Accept-Language header when no session" do
        request.headers["Accept-Language"] = "da,en;q=0.5"
        get :index
        expect(I18n.locale).to eq(:da)
      end

      it "parses complex Accept-Language header correctly" do
        request.headers["Accept-Language"] = "fr-FR,fr;q=0.9,es-ES;q=0.8,es;q=0.7,en;q=0.6"
        get :index
        expect(I18n.locale).to eq(:es) # First supported locale from the header
      end

      it "uses default locale when Accept-Language has no supported locales" do
        request.headers["Accept-Language"] = "fr,de;q=0.5"
        get :index
        expect(I18n.locale).to eq(:en)
      end

      it "uses default locale when no Accept-Language header" do
        get :index
        expect(I18n.locale).to eq(:en)
      end
    end
  end

  describe "#extract_locale_from_accept_language_header" do
    it "returns nil when no Accept-Language header present" do
      get :index
      expect(I18n.locale).to eq(:en)
    end

    it "parses single locale from header" do
      request.headers["Accept-Language"] = "es"
      get :index
      expect(I18n.locale).to eq(:es)
    end

    it "parses locale with country code" do
      request.headers["Accept-Language"] = "es-ES"
      get :index
      expect(I18n.locale).to eq(:es)
    end

    it "parses locale with quality values" do
      request.headers["Accept-Language"] = "da;q=0.9,en;q=0.8"
      get :index
      expect(I18n.locale).to eq(:da)
    end

    it "returns first supported locale from list" do
      request.headers["Accept-Language"] = "fr,es,da,en"
      get :index
      expect(I18n.locale).to eq(:es) # First supported locale
    end

    it "ignores unsupported locales" do
      request.headers["Accept-Language"] = "fr,de,pt,es"
      get :index
      expect(I18n.locale).to eq(:es)
    end
  end

  describe "locale persistence across requests" do
    let(:user) { User.create!(auth0_sub: "auth0|456", display_name: "Test User", email: "test2@example.com") }

    context "when authenticated user changes locale" do
      before do
        allow(controller).to receive(:current_user).and_return(user)
        user.preferences = { "language" => "es" }
        user.save!
      end

      it "maintains locale for subsequent requests" do
        get :index
        expect(I18n.locale).to eq(:es)

        # Simulate another request
        get :index
        expect(I18n.locale).to eq(:es)
      end
    end

    context "when guest user uses session" do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it "maintains session locale across requests" do
        session[:locale] = "da"
        get :index
        expect(I18n.locale).to eq(:da)

        # Simulate another request with same session
        get :index
        expect(I18n.locale).to eq(:da)
      end
    end
  end

  describe "locale switching" do
    context "when user updates language preference" do
      let(:user) { User.create!(auth0_sub: "auth0|789", display_name: "Test User", email: "test3@example.com") }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "immediately reflects the new locale" do
        user.preferences = { "language" => "en" }
        user.save!
        get :index
        expect(I18n.locale).to eq(:en)

        user.preferences = { "language" => "da" }
        user.save!
        get :index
        expect(I18n.locale).to eq(:da)
      end
    end
  end

  describe "error handling" do
    context "when locale setting fails" do
      before do
        allow(I18n).to receive(:locale=).and_raise(StandardError.new("Locale error"))
      end

      it "gracefully falls back to default locale" do
        expect { get :index }.not_to raise_error
      end
    end
  end

  describe "dynamic locale validation with LocaleService" do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
    end

    context "when LocaleService provides available locales" do
      it "validates session locale against LocaleService available locales" do
        session[:locale] = "es" # This should be available (en, es, da)
        get :index
        expect(I18n.locale).to eq(:es)
      end

      it "rejects session locale not in LocaleService available locales" do
        session[:locale] = "fr" # Not in the available locales (en, es, da)
        get :index
        expect(I18n.locale).to eq(:en) # Falls back to default
      end

      it "validates Accept-Language header against LocaleService available locales" do
        request.headers["Accept-Language"] = "da,es;q=0.9,fr;q=0.8"
        get :index
        expect(I18n.locale).to eq(:da) # First supported locale from LocaleService
      end

      it "ignores Accept-Language locales not in LocaleService" do
        request.headers["Accept-Language"] = "fr,de,it,es" # Only es is available
        get :index
        expect(I18n.locale).to eq(:es)
      end

      it "falls back to default when no LocaleService locales match Accept-Language" do
        request.headers["Accept-Language"] = "fr,de,it" # None available in LocaleService
        get :index
        expect(I18n.locale).to eq(:en)
      end
    end

    context "when authenticated user has language preference" do
      let(:user) { User.create!(auth0_sub: "auth0|999", display_name: "Test User", email: "test@example.com") }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "validates user language preference against LocaleService" do
        user.preferences = { "language" => "es" } # Available locale
        user.save!
        get :index
        expect(I18n.locale).to eq(:es)
      end

      it "falls back when user language preference not in LocaleService" do
        user.preferences = { "language" => "fr" } # Not in available locales (en, es, da)
        user.save(validate: false) # Skip validation for this test scenario
        session[:locale] = "da" # Available fallback
        get :index
        expect(I18n.locale).to eq(:da) # Falls back to session
      end
    end
  end
end
