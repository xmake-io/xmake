@0xd30600b3651feef7;

using Cxx = import "/capnp/c++.capnp";
$Cxx.namespace("test::proto");

struct Message {
  text @0 :Text;
}
