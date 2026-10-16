-- Standard registrations retain Xmake's scope and set/add semantics.
interp_add_scopeapis("example_profile.set_message", "example_profile.add_tags", {kind = "values"})
interp_add_scopeapis("target.set_example_profile", {kind = "values"})

-- Execute the project's declarations only after the extension APIs are available.
example_configure_profiles()
