module Cline
  class GlobalSettings
    # Browser integration and viewport settings
    module Browser
      # Browser viewport settings
      class BrowserViewport < Schema
        # @return [Integer] Viewport width
        attribute :width, :integer

        # @return [Integer] Viewport height
        attribute :height, :integer
      end

      # Browser configuration settings
      class BrowserSettings < Schema
        # @return [BrowserViewport] Browser viewport dimensions
        attribute :viewport, BrowserViewport

        # @return [Boolean] Remote browser enabled flag
        attribute :remote_browser_enabled, :boolean

        # @return [String] Remote browser host address
        attribute :remote_browser_host, :string

        # @return [String] Chrome executable path
        attribute :chrome_executable_path, :string

        # @return [Boolean] Disable browser tool use
        attribute :disable_tool_use, :boolean

        # @return [String] Custom browser arguments
        attribute :custom_args, :string
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @return [BrowserSettings] Browser configuration settings
          attribute :browser_settings, BrowserSettings
        end
      end
    end
  end
end
