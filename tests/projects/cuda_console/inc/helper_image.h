/**
 * Copyright 1993-2013 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

// These are helper functions for the SDK samples (image,bitmap)
#ifndef HELPER_IMAGE_H
#define HELPER_IMAGE_H

#include <string>
#include <fstream>
#include <vector>
#include <iostream>
#include <algorithm>

#include <assert.h>
#include <exception.h>
#include <math.h>

#ifndef MIN
#define MIN(a,b) ((a < b) ? a : b)
#endif
#ifndef MAX
#define MAX(a,b) ((a > b) ? a : b)
#endif

#ifndef EXIT_WAIVED
#define EXIT_WAIVED 2
#endif

#include <helper_string.h>

// namespace unnamed (internal)
namespace
{
    //! size of PGM file header
    const unsigned int PGMHeaderSize = 0x40;

    // types

    //! Data converter from unsigned char / unsigned byte to type T
    template<class T>
    struct ConverterFromUByte;

    //! Data converter from unsigned char / unsigned byte
    template<>
    struct ConverterFromUByte<unsigned char>
    {
        //! Conversion operator
        //! @return converted value
        //! @param  val  value to convert
        float operator()(const unsigned char &val)
        {
            return static_cast<unsigned char>(val);
        }
    };

    //! Data converter from unsigned char / unsigned byte to float
    template<>
    struct ConverterFromUByte<float>
    {
        //! Conversion operator
        //! @return converted value
        //! @param  val  value to convert
        float operator()(const unsigned char &val)
        {
            return static_cast<float>(val) / 255.0f;
        }
    };

    //! Data converter from unsigned char / unsigned byte to type T
    template<class T>
    struct ConverterToUByte;

    //! Data converter from unsigned char / unsigned byte to unsigned int
    template<>
    struct ConverterToUByte<unsigned char>
    {
        //! Conversion operator (essentially a passthru
        //! @return converted value
        //! @param  val  value to convert
        unsigned char operator()(const unsigned char &val)
        {
            return val;
        }
    };

    //! Data converter from unsigned char / unsigned byte to unsigned int
    template<>
    struct ConverterToUByte<float>
    {
        //! Conversion operator
        //! @return converted value
        //! @param  val  value to convert
        unsigned char operator()(const float &val)
        {
            return static_cast<unsigned char>(val * 255.0f);
        }
    };
}

#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#ifndef FOPEN
#define FOPEN(fHandle,filename,mode) fopen_s(&fHandle, filename, mode)
#endif
#ifndef FOPEN_FAIL
#define FOPEN_FAIL(result) (result != 0)
#endif
#ifndef SSCANF
#define SSCANF sscanf_s
#endif
#else
#ifndef FOPEN
#define FOPEN(fHandle,filename,mode) (fHandle = fopen(filename, mode))
#endif
#ifndef FOPEN_FAIL
#define FOPEN_FAIL(result) (result == NULL)
#endif
#ifndef SSCANF
#define SSCANF sscanf
#endif
#endif

inline bool
__loadPPM(const char *file, unsigned char **data,
          unsigned int *w, unsigned int *h, unsigned int *channels)
{
    FILE *fp = NULL;

    if (FOPEN_FAIL(FOPEN(fp, file, "rb")))
    {
        std::cerr << "__LoadPPM() : Failed to open file: " << file << std::endl;
        return false;
    }

    // check header
    char header[PGMHeaderSize];

    if (fgets(header, PGMHeaderSize, fp) == NULL)
    {
        std::cerr << "__LoadPPM() : reading PGM header returned NULL" << std::endl;
        return false;
    }

    if (strncmp(header, "P5", 2) == 0)
    {
        *channels = 1;
    }
    else if (strncmp(header, "P6", 2) == 0)
    {
        *channels = 3;
    }
    else
    {
        std::cerr << "__LoadPPM() : File is not a PPM or PGM image" << std::endl;
        *channels = 0;
        return false;
    }

    // parse header, read maxval, width and height
    unsigned int width = 0;
    unsigned int height = 0;
    unsigned int maxval = 0;
    unsigned int i = 0;

    while (i < 3)
    {
        if (fgets(header, PGMHeaderSize, fp) == NULL)
        {
            std::cerr << "__LoadPPM() : reading PGM header returned NULL" << std::endl;
            return false;
        }

        if (header[0] == '#')
        {
            continue;
        }

        if (i == 0)
        {
            i += SSCANF(header, "%u %u %u", &width, &height, &maxval);
        }
        else if (i == 1)
        {
            i += SSCANF(header, "%u %u", &height, &maxval);
        }
        else if (i == 2)
        {
            i += SSCANF(header, "%u", &maxval);
        }
    }

    // check if given handle for the data is initialized
    if (NULL != *data)
    {
        if (*w != width || *h != height)
        {
            std::cerr << "__LoadPPM() : Invalid image dimensions." << std::endl;
        }
    }
    else
    {
        *data = (unsigned char *) malloc(sizeof(unsigned char) * width * height **channels);
        *w = width;
        *h = height;
    }

    // read and close file
    if (fread(*data, sizeof(unsigned char), width * height **channels, fp) == 0)
    {
        std::cerr << "__LoadPPM() read data returned error." << std::endl;
    }

    fclose(fp);

    return true;
}

template <class T>
inline bool
sdkLoadPGM(const char *file, T **data, unsigned int *w, unsigned int *h)
{
    unsigned char *idata = NULL;
    unsigned int channels;

    if (true != __loadPPM(file, &idata, w, h, &channels))
    {
        return false;
    }

    unsigned int size = *w **h * channels;

    // initialize mem if necessary
    // the correct size is checked / set in loadPGMc()
    if (NULL == *data)
    {
        *data = (T *) malloc(sizeof(T) * size);
    }

    // copy and cast data
    std::transform(idata, idata + size, *data, ConverterFromUByte<T>());

    free(idata);

    return true;
}

template <class T>
inline bool
sdkLoadPPM4(const char *file, T **data,
            unsigned int *w,unsigned int *h)
{
    unsigned char *idata = 0;
    unsigned int channels;

    if (__loadPPM(file, &idata, w, h, &channels))
    {
        // pad 4th component
        int size = *w **h;
        // keep the original pointer
        unsigned char *idata_orig = idata;
        *data = (T *) malloc(sizeof(T) * size * 4);
        unsigned char *ptr = *data;

        for (int i=0; i<size; i++)
        {
            *ptr++ = *idata++;
            *ptr++ = *idata++;
            *ptr++ = *idata++;
            *ptr++ = 0;
        }

        free(idata_orig);
        return true;
    }
    else
    {
        free(idata);
        return false;
    }
}

inline bool
__savePPM(const char *file, unsigned char *data,
          unsigned int w, unsigned int h, unsigned int channels)
{
    assert(NULL != data);
    assert(w > 0);
    assert(h > 0);

    std::fstream fh(file, std::fstream::out | std::fstream::binary);

    if (fh.bad())
    {
        std::cerr << "__savePPM() : Opening file failed." << std::endl;
        return false;
    }

    if (channels == 1)
    {
        fh << "P5\n";
    }
    else if (channels == 3)
    {
        fh << "P6\n";
    }
    else
    {
        std::cerr << "__savePPM() : Invalid number of channels." << std::endl;
        return false;
    }

    fh << w << "\n" << h << "\n" << 0xff << std::endl;

    for (unsigned int i = 0; (i < (w*h*channels)) && fh.good(); ++i)
    {
        fh << data[i];
    }

    fh.flush();

    if (fh.bad())
    {
        std::cerr << "__savePPM() : Writing data failed." << std::endl;
        return false;
    }

    fh.close();

    return true;
}

template<class T>
inline bool
sdkSavePGM(const char *file, T *data, unsigned int w, unsigned int h)
{
    unsigned int size = w * h;
    unsigned char *idata =
        (unsigned char *) malloc(sizeof(unsigned char) * size);

    std::transform(data, data + size, idata, ConverterToUByte<T>());

    // write file
    bool result = __savePPM(file, idata, w, h, 1);

    // cleanup
    free(idata);

    return result;
}

inline bool
sdkSavePPM4ub(const char *file, unsigned char *data,
              unsigned int w, unsigned int h)
{
    // strip 4th component
    int size = w * h;
    unsigned char *ndata = (unsigned char *) malloc(sizeof(unsigned char) * size*3);
    unsigned char *ptr = ndata;

    for (int i=0; i<size; i++)
    {
        *ptr++ = *data++;
        *ptr++ = *data++;
        *ptr++ = *data++;
        data++;
    }

    bool result = __savePPM(file, ndata, w, h, 3);
    free(ndata);
    return result;
}


//////////////////////////////////////////////////////////////////////////////
//! Read file \filename and return the data
//! @return bool if reading the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  uninitialized pointer, returned initialized and pointing to
//!        the data read
//! @param len  number of data elements in data, -1 on error
//////////////////////////////////////////////////////////////////////////////
template<class T>
inline bool
sdkReadFile(const char *filename, T **data, unsigned int *len, bool verbose)
{
    // check input arguments
    assert(NULL != filename);
    assert(NULL != len);

    // intermediate storage for the data read
    std::vector<T>  data_read;

    // open file for reading
    FILE *fh = NULL;

    // check if filestream is valid
    if (FOPEN_FAIL(FOPEN(fh, filename, "r")))
    {
        printf("Unable to open input file: %s\n", filename);
        return false;
    }

    // read all data elements
    T token;

    while (!feof(fh))
    {
        fscanf(fh, "%f", &token);
        data_read.push_back(token);
    }

    // the last element is read twice
    data_read.pop_back();
    fclose(fh);

    // check if the given handle is already initialized
    if (NULL != *data)
    {
        if (*len != data_read.size())
        {
            std::cerr << "sdkReadFile() : Initialized memory given but "
                      << "size  mismatch with signal read "
                      << "(data read / data init = " << (unsigned int)data_read.size()
                      <<  " / " << *len << ")" << std::endl;

            return false;
        }
    }
    else
    {
        // allocate storage for the data read
        *data = (T *) malloc(sizeof(T) * data_read.size());
        // store signal size
        *len = static_cast<unsigned int>(data_read.size());
    }

    // copy data
    memcpy(*data, &data_read.front(), sizeof(T) * data_read.size());

    return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Read file \filename and return the data
//! @return bool if reading the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  uninitialized pointer, returned initialized and pointing to
//!        the data read
//! @param len  number of data elements in data, -1 on error
//////////////////////////////////////////////////////////////////////////////
template<class T>
inline bool
sdkReadFileBlocks(const char *filename, T **data, unsigned int *len, unsigned int block_num, unsigned int block_size, bool verbose)
{
    // check input arguments
    assert(NULL != filename);
    assert(NULL != len);

    // open file for reading
    FILE *fh = fopen(filename, "rb");

    if (fh == NULL && verbose)
    {
        std::cerr << "sdkReadFile() : Opening file failed." << std::endl;
        return false;
    }

    // check if the given handle is already initialized
    // allocate storage for the data read
    data[block_num] = (T *) malloc(block_size);

    // read all data elements
    fseek(fh, block_num * block_size, SEEK_SET);
    *len = fread(data[block_num], sizeof(T), block_size/sizeof(T), fh);

    fclose(fh);

    return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Write a data file \filename
//! @return true if writing the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  data to write
//! @param len  number of data elements in data, -1 on error
//! @param epsilon  epsilon for comparison
//////////////////////////////////////////////////////////////////////////////
template<class T, class S>
inline bool
sdkWriteFile(const char *filename, const T *data, unsigned int len,
             const S epsilon, bool verbose, bool append = false)
{
    assert(NULL != filename);
    assert(NULL != data);

    // open file for writing
    //    if (append) {
    std::fstream fh(filename, std::fstream::out | std::fstream::ate);

    if (verbose)
    {
        std::cerr << "sdkWriteFile() : Open file " << filename << " for write/append." << std::endl;
    }

    /*    } else {
            std::fstream fh(filename, std::fstream::out);
            if (verbose) {
                std::cerr << "sdkWriteFile() : Open file " << filename << " for write." << std::endl;
            }
        }
    */

    // check if filestream is valid
    if (! fh.good())
    {
        if (verbose)
        {
            std::cerr << "sdkWriteFile() : Opening file failed." << std::endl;
        }

        return false;
    }

    // first write epsilon
    fh << "# " << epsilon << "\n";

    // write data
    for (unsigned int i = 0; (i < len) && (fh.good()); ++i)
    {
        fh << data[i] << ' ';
    }

    // Check if writing succeeded
    if (! fh.good())
    {
        if (verbose)
        {
            std::cerr << "sdkWriteFile() : Writing file failed." << std::endl;
        }

        return false;
    }

    // file ends with nl
    fh << std::endl;

    return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Compare two arrays of arbitrary type
//! @return  true if \a reference and \a data are identical, otherwise false
//! @param reference  timer_interface to the reference data / gold image
//! @param data       handle to the computed data
//! @param len        number of elements in reference and data
//! @param epsilon    epsilon to use for the comparison
//////////////////////////////////////////////////////////////////////////////
template<class T, class S>
inline bool
compareData(const T *reference, const T *data, const unsigned int len,
            const S epsilon, const float threshold)
{
    assert(epsilon >= 0);

    bool result = true;
    unsigned int error_count = 0;

    for (unsigned int i = 0; i < len; ++i)
    {
        float diff = (float)reference[i] - (float)data[i];
        bool comp = (diff <= epsilon) && (diff >= -epsilon);
        result &= comp;

        error_count += !comp;

#if 0

        if (! comp)
        {
            std::cerr << "ERROR, i = " << i << ",\t "
                      << reference[i] << " / "
                      << data[i]
                      << " (reference / data)\n";
        }

#endif
    }

    if (threshold == 0.0f)
    {
        return (result) ? true : false;
    }
    else
    {
        if (error_count)
        {
            printf("%4.2f(%%) of bytes mismatched (count=%d)\n", (float)error_count*100/(float)len, error_count);
        }

        return (len*threshold > error_count) ? true : false;
    }
}

#ifndef __MIN_EPSILON_ERROR
#define __MIN_EPSILON_ERROR 1e-3f
#endif

//////////////////////////////////////////////////////////////////////////////
//! Compare two arrays of arbitrary type
//! @return  true if \a reference and \a data are identical, otherwise false
//! @param reference  handle to the reference data / gold image
//! @param data       handle to the computed data
//! @param len        number of elements in reference and data
//! @param epsilon    epsilon to use for the comparison
//! @param epsilon    threshold % of (# of bytes) for pass/fail
//////////////////////////////////////////////////////////////////////////////
template<class T, class S>
inline bool
compareDataAsFloatThreshold(const T *reference, const T *data, const unsigned int len,
                            const S epsilon, const float threshold)
{
    assert(epsilon >= 0);

    // If we set epsilon to be 0, let's set a minimum threshold
    float max_error = MAX((float)epsilon, __MIN_EPSILON_ERROR);
    int error_count = 0;
    bool result = true;

    for (unsigned int i = 0; i < len; ++i)
    {
        float diff = fabs((float)reference[i] - (float)data[i]);
        bool comp = (diff < max_error);
        result &= comp;

        if (! comp)
        {
            error_count++;
#if 0

            if (error_count < 50)
            {
                printf("\n    ERROR(epsilon=%4.3f), i=%d, (ref)0x%02x / (data)0x%02x / (diff)%d\n",
                       max_error, i,
                       *(unsigned int *)&reference[i],
                       *(unsigned int *)&data[i],
                       (unsigned int)diff);
            }

#endif
        }
    }

    if (threshold == 0.0f)
    {
        if (error_count)
        {
            printf("total # of errors = %d\n", error_count);
        }

        return (error_count == 0) ? true : false;
    }
    else
    {
        if (error_count)
        {
            printf("%4.2f(%%) of bytes mismatched (count=%d)\n", (float)error_count*100/(float)len, error_count);
        }

        return ((len*threshold > error_count) ? true : false);
    }
}

inline
void sdkDumpBin(void *data, unsigned int bytes, const char *filename)
{
    printf("sdkDumpBin: <%s>\n", filename);
    FILE *fp;
    FOPEN(fp, filename, "wb");
    fwrite(data, bytes, 1, fp);
    fflush(fp);
    fclose(fp);
}

inline
bool sdkCompareBin2BinUint(const char *src_file, const char *ref_file, unsigned int nelements, const float epsilon, const float threshold, char *exec_path)
{
    unsigned int *src_buffer, *ref_buffer;
    FILE *src_fp = NULL, *ref_fp = NULL;

    unsigned long error_count = 0;
    size_t fsize = 0;

    if (FOPEN_FAIL(FOPEN(src_fp, src_file, "rb")))
    {
        printf("compareBin2Bin <unsigned int> unable to open src_file: %s\n", src_file);
        error_count++;
    }

    char *ref_file_path = sdkFindFilePath(ref_file, exec_path);

    if (ref_file_path == NULL)
    {
        printf("compareBin2Bin <unsigned int>  unable to find <%s> in <%s>\n", ref_file, exec_path);
        printf(">>> Check info.xml and [project//data] folder <%s> <<<\n", ref_file);
        printf("Aborting comparison!\n");
        printf("  FAILED\n");
        error_count++;

        if (src_fp)
        {
            fclose(src_fp);
        }

        if (ref_fp)
        {
            fclose(ref_fp);
        }
    }
    else
    {
        if (FOPEN_FAIL(FOPEN(ref_fp, ref_file_path, "rb")))
        {
            printf("compareBin2Bin <unsigned int>  unable to open ref_file: %s\n", ref_file_path);
            error_count++;
        }

        if (src_fp && ref_fp)
        {
            src_buffer = (unsigned int *)malloc(nelements*sizeof(unsigned int));
            ref_buffer = (unsigned int *)malloc(nelements*sizeof(unsigned int));

            fsize = fread(src_buffer, nelements, sizeof(unsigned int), src_fp);
            fsize = fread(ref_buffer, nelements, sizeof(unsigned int), ref_fp);

            printf("> compareBin2Bin <unsigned int> nelements=%d, epsilon=%4.2f, threshold=%4.2f\n", nelements, epsilon, threshold);
            printf("   src_file <%s>, size=%d bytes\n", src_file, (int)fsize);
            printf("   ref_file <%s>, size=%d bytes\n", ref_file_path, (int)fsize);

            if (!compareData<unsigned int, float>(ref_buffer, src_buffer, nelements, epsilon, threshold))
            {
                error_count++;
            }

            fclose(src_fp);
            fclose(ref_fp);

            free(src_buffer);
            free(ref_buffer);
        }
        else
        {
            if (src_fp)
            {
                fclose(src_fp);
            }

            if (ref_fp)
            {
                fclose(ref_fp);
            }
        }
    }

    if (error_count == 0)
    {
        printf("  OK\n");
    }
    else
    {
        printf("  FAILURE: %d errors...\n", (unsigned int)error_count);
    }

    return (error_count == 0);  // returns true if all pixels pass
}

inline
bool sdkCompareBin2BinFloat(const char *src_file, const char *ref_file, unsigned int nelements, const float epsilon, const float threshold, char *exec_path)
{
    float *src_buffer, *ref_buffer;
    FILE *src_fp = NULL, *ref_fp = NULL;
    size_t fsize = 0;

    unsigned long error_count = 0;

    if (FOPEN_FAIL(FOPEN(src_fp, src_file, "rb")))
    {
        printf("compareBin2Bin <float> unable to open src_file: %s\n", src_file);
        error_count = 1;
    }

    char *ref_file_path = sdkFindFilePath(ref_file, exec_path);

    if (ref_file_path == NULL)
    {
        printf("compareBin2Bin <float> unable to find <%s> in <%s>\n", ref_file, exec_path);
        printf(">>> Check info.xml and [project//data] folder <%s> <<<\n", exec_path);
        printf("Aborting comparison!\n");
        printf("  FAILED\n");
        error_count++;

        if (src_fp)
        {
            fclose(src_fp);
        }

        if (ref_fp)
        {
            fclose(ref_fp);
        }
    }
    else
    {
        if (FOPEN_FAIL(FOPEN(ref_fp, ref_file_path, "rb")))
        {
            printf("compareBin2Bin <float> unable to open ref_file: %s\n", ref_file_path);
            error_count = 1;
        }

        if (src_fp && ref_fp)
        {
            src_buffer = (float *)malloc(nelements*sizeof(float));
            ref_buffer = (float *)malloc(nelements*sizeof(float));

            fsize = fread(src_buffer, nelements, sizeof(float), src_fp);
            fsize = fread(ref_buffer, nelements, sizeof(float), ref_fp);

            printf("> compareBin2Bin <float> nelements=%d, epsilon=%4.2f, threshold=%4.2f\n", nelements, epsilon, threshold);
            printf("   src_file <%s>, size=%d bytes\n", src_file, (int)fsize);
            printf("   ref_file <%s>, size=%d bytes\n", ref_file_path, (int)fsize);

            if (!compareDataAsFloatThreshold<float, float>(ref_buffer, src_buffer, nelements, epsilon, threshold))
            {
                error_count++;
            }

            fclose(src_fp);
            fclose(ref_fp);

            free(src_buffer);
            free(ref_buffer);
        }
        else
        {
            if (src_fp)
            {
                fclose(src_fp);
            }

            if (ref_fp)
            {
                fclose(ref_fp);
            }
        }
    }

    if (error_count == 0)
    {
        printf("  OK\n");
    }
    else
    {
        printf("  FAILURE: %d errors...\n", (unsigned int)error_count);
    }

    return (error_count == 0);  // returns true if all pixels pass
}

inline bool
sdkCompareL2fe(const float *reference, const float *data,
               const unsigned int len, const float epsilon)
{
    assert(epsilon >= 0);

    float error = 0;
    float ref = 0;

    for (unsigned int i = 0; i < len; ++i)
    {

        float diff = reference[i] - data[i];
        error += diff * diff;
        ref += reference[i] * reference[i];
    }

    float normRef = sqrtf(ref);

    if (fabs(ref) < 1e-7)
    {
#ifdef _DEBUG
        std::cerr << "ERROR, reference l2-norm is 0\n";
#endif
        return false;
    }

    float normError = sqrtf(error);
    error = normError / normRef;
    bool result = error < epsilon;
#ifdef _DEBUG

    if (! result)
    {
        std::cerr << "ERROR, l2-norm error "
                  << error << " is greater than epsilon " << epsilon << "\n";
    }

#endif

    return result;
}

inline bool
sdkLoadPPMub(const char *file, unsigned char **data,
             unsigned int *w,unsigned int *h)
{
    unsigned int channels;
    return __loadPPM(file, data, w, h, &channels);
}

inline bool
sdkLoadPPM4ub(const char *file, unsigned char **data,
              unsigned int *w, unsigned int *h)
{
    unsigned char *idata = 0;
    unsigned int channels;

    if (__loadPPM(file, &idata, w, h, &channels))
    {
        // pad 4th component
        int size = *w **h;
        // keep the original pointer
        unsigned char *idata_orig = idata;
        *data = (unsigned char *) malloc(sizeof(unsigned char) * size * 4);
        unsigned char *ptr = *data;

        for (int i=0; i<size; i++)
        {
            *ptr++ = *idata++;
            *ptr++ = *idata++;
            *ptr++ = *idata++;
            *ptr++ = 0;
        }

        free(idata_orig);
        return true;
    }
    else
    {
        free(idata);
        return false;
    }
}


inline bool
sdkComparePPM(const char *src_file, const char *ref_file,
              const float epsilon, const float threshold, bool verboseErrors)
{
    unsigned char *src_data, *ref_data;
    unsigned long error_count = 0;
    unsigned int ref_width, ref_height;
    unsigned int src_width, src_height;

    if (src_file == NULL || ref_file == NULL)
    {
        if (verboseErrors)
        {
            std::cerr << "PPMvsPPM: src_file or ref_file is NULL.  Aborting comparison\n";
        }

        return false;
    }

    if (verboseErrors)
    {
        std::cerr << "> Compare (a)rendered:  <" << src_file << ">\n";
        std::cerr << ">         (b)reference: <" << ref_file << ">\n";
    }


    if (sdkLoadPPM4ub(ref_file, &ref_data, &ref_width, &ref_height) != true)
    {
        if (verboseErrors)
        {
            std::cerr << "PPMvsPPM: unable to load ref image file: "<< ref_file << "\n";
        }

        return false;
    }

    if (sdkLoadPPM4ub(src_file, &src_data, &src_width, &src_height) != true)
    {
        std::cerr << "PPMvsPPM: unable to load src image file: " << src_file << "\n";
        return false;
    }

    if (src_height != ref_height || src_width != ref_width)
    {
        if (verboseErrors) std::cerr << "PPMvsPPM: source and ref size mismatch (" << src_width <<
                                         "," << src_height << ")vs(" << ref_width << "," << ref_height << ")\n";
    }

    if (verboseErrors) std::cerr << "PPMvsPPM: comparing images size (" << src_width <<
                                     "," << src_height << ") epsilon(" << epsilon << "), threshold(" << threshold*100 << "%)\n";

    if (compareData(ref_data, src_data, src_width*src_height*4, epsilon, threshold) == false)
    {
        error_count=1;
    }

    if (error_count == 0)
    {
        if (verboseErrors)
        {
            std::cerr << "    OK\n\n";
        }
    }
    else
    {
        if (verboseErrors)
        {
            std::cerr << "    FAILURE!  "<<error_count<<" errors...\n\n";
        }
    }

    return (error_count == 0)? true : false;  // returns true if all pixels pass
}

inline bool
sdkComparePGM(const char *src_file, const char *ref_file,
              const float epsilon, const float threshold, bool verboseErrors)
{
    unsigned char *src_data = 0, *ref_data = 0;
    unsigned long error_count = 0;
    unsigned int ref_width, ref_height;
    unsigned int src_width, src_height;

    if (src_file == NULL || ref_file == NULL)
    {
        if (verboseErrors)
        {
            std::cerr << "PGMvsPGM: src_file or ref_file is NULL.  Aborting comparison\n";
        }

        return false;
    }

    if (verboseErrors)
    {
        std::cerr << "> Compare (a)rendered:  <" << src_file << ">\n";
        std::cerr << ">         (b)reference: <" << ref_file << ">\n";
    }


    if (sdkLoadPPMub(ref_file, &ref_data, &ref_width, &ref_height) != true)
    {
        if (verboseErrors)
        {
            std::cerr << "PGMvsPGM: unable to load ref image file: "<< ref_file << "\n";
        }

        return false;
    }

    if (sdkLoadPPMub(src_file, &src_data, &src_width, &src_height) != true)
    {
        std::cerr << "PGMvsPGM: unable to load src image file: " << src_file << "\n";
        return false;
    }

    if (src_height != ref_height || src_width != ref_width)
    {
        if (verboseErrors) std::cerr << "PGMvsPGM: source and ref size mismatch (" << src_width <<
                                         "," << src_height << ")vs(" << ref_width << "," << ref_height << ")\n";
    }

    if (verboseErrors) std::cerr << "PGMvsPGM: comparing images size (" << src_width <<
                                     "," << src_height << ") epsilon(" << epsilon << "), threshold(" << threshold*100 << "%)\n";

    if (compareData(ref_data, src_data, src_width*src_height, epsilon, threshold) == false)
    {
        error_count=1;
    }

    if (error_count == 0)
    {
        if (verboseErrors)
        {
            std::cerr << "    OK\n\n";
        }
    }
    else
    {
        if (verboseErrors)
        {
            std::cerr << "    FAILURE!  "<<error_count<<" errors...\n\n";
        }
    }

    return (error_count == 0)? true : false;  // returns true if all pixels pass
}

#endif // HELPER_IMAGE_H
