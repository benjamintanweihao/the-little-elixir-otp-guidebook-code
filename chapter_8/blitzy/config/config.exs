use Mix.Config

config :blitzy, master_node: :"a@127.0.0.1"

config :blitzy, slave_nodes: [:"b@127.0.0.1",
                              :"c@127.0.0.1",
                              :"d@127.0.0.1"]


