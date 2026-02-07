#include <iostream>
#include <OpenImageIO/imageio.h>
#include <openssl/evp.h>
#include <OpenColorIO/OpenColorIO.h>

using namespace std;

int main(int argc, char** argv)
{
    namespace OCIO = OCIO_NAMESPACE;
    EVP_MD_CTX* sha256 = EVP_MD_CTX_new();
    EVP_DigestInit_ex(sha256, EVP_sha256(), nullptr);
    auto write_image = OIIO::ImageOutput::create("test.png");
    cout << "hello world!" << endl;
    return 0;
}
