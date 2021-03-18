# local_image_provider_platform_interface

A common platform interface for the [`local_image_provider`][1] plugin.

This interface allows platform-specific implementations of the `local_image_provider`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `local_image_provider`, extend
[`LocalImageProviderPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`LocalImageProviderPlatform` by calling
`LocalImageProviderPlatform.instance = MyPlatformLocalImageProvider()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: ../local_image_provider
[2]: lib/local_image_provider_platform_interface.dart