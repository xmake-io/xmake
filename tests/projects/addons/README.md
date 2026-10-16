# Standalone addon examples

Each subdirectory includes a user project, its addon, and a local package repository:

| Example | Demonstrates |
| --- | --- |
| `includes` | Shared configuration options through an addon includes file. |
| `description_api` | Custom description scope and target setter, consumed by a rule. |
| `functions` | A description-domain helper that creates a target and restores scope. |
| `rules_modules` | Namespaced rules/modules and addon-internal `@self` imports. |

Use a current Xmake dev build with addon support, Git, and a native C compiler.
Enter one of these directories and run `xmake -y`, then `xmake run hello`.
Each directory's README explains installation, expected output, editing, and cleanup.

For the two description extension examples, the addon includes file invokes a
project-defined configuration function after registering its APIs/helpers. This is an
example-level convention, allowing the first project scan to complete before automatic
installation; it is not a new Xmake lifecycle hook.

To try an example from the Xmake source root:

```sh
cd tests/projects/addons/includes
xmake -y
xmake run hello
```

Repeat from `description_api`, `functions`, or `rules_modules` to try the other examples.
All addon sources are local. In a fresh environment, `xmake global --network=private`
avoids initializing remote repositories. Set `XMAKE_GLOBALDIR` to a separate directory
before running any commands if you want to isolate the sample addon installations.
