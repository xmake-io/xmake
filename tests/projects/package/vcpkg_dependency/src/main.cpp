#include <OpenColorIO/OpenColorIO.h>
#include <OpenImageIO/imageio.h>
#include <boost/system/error_code.hpp>
#include <boost/filesystem.hpp>

int main(int argc, char **argv) {
    // test for opencolorio, opencolorio is one of the dependencies of openimageio.
    auto transform = OCIO_NAMESPACE::ColorSpaceTransform::Create();

    // test for openimageio.
    auto write_image = OIIO::ImageInput::open("test.png");

    // test for boost-system, boost-system is one of the dependencies of boost-system.
    boost::system::error_code ec;

    // test for boost-filesystem.
    boost::filesystem::exists("test.png", ec);

    return 0;
}
