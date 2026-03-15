# Installing plugin in vim: the quickest guide

1. Download a plugin. Usually plugin itself is a directory containing `plugin` and/or `autoload` subdirectories.
2. Determine your `.vim` directory location. It depends on OS and Vim fork/modification (e.g. Neovim). Usually it's where your config is stored.
3. Place a plugin directory inside of a `pack/plugins/start/` inside of your `.vim`, creating necessary directories if they're doesn't exist yet.

For more info see `:help using-scripts` and `:help packages`.
