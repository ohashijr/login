# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :login,
  ecto_repos: [Login.Repo]

# Configures the endpoint
config :login, Login.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "x4pIZQi+bdl+qTlQul4Aa10Rb8uwLRmrjU8gX7UloaDDMOfqPthr8/CHNN2wRi+4",
  render_errors: [view: Login.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Login.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Login.User,
  repo: Login.Repo,
  module: Login,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]

config :coherence, Login.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
# %% End Coherence Configuration %%

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
