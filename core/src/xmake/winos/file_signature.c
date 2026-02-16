/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        file_signature.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "file_signature"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <windows.h>
#include <wintrust.h>
#include <softpub.h>
#include <wincrypt.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
/// the file signature info type
typedef struct __tb_file_signature_info_t {
    /// is the file digitally signed?
    tb_bool_t           is_signed;

    /// is the signature valid and trusted by the OS?
    tb_bool_t           is_trusted;

    /// the name of the signer (e.g., "Microsoft Corporation")
    /// tbox uses UTF-8 by default for tb_char_t
    tb_char_t           signer_name[256];

}tb_file_signature_info_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_wchar_t* tb_path_to_wchar(tb_char_t const* path, tb_wchar_t* buffer, tb_size_t size) {
    // check
    tb_assert_and_check_return_val(path && buffer && size, tb_null);

    // convert
    if (MultiByteToWideChar(CP_UTF8, 0, path, -1, buffer, (int)size) > 0)
        return buffer;

    return tb_null;
}

static tb_bool_t tb_file_get_signature_info(tb_char_t const* filepath, tb_file_signature_info_t* info) {
    // check
    tb_assert_and_check_return_val(filepath && info, tb_false);

    // init info
    tb_memset(info, 0, sizeof(tb_file_signature_info_t));

    // convert path
    tb_wchar_t wide_path[TB_PATH_MAXN];
    if (!tb_path_to_wchar(filepath, wide_path, TB_PATH_MAXN)) return tb_false;

    // init file info
    WINTRUST_FILE_INFO file_data = {0};
    file_data.cbStruct = sizeof(file_data);
    file_data.pcwszFilePath = wide_path;
    file_data.hFile = NULL;
    file_data.pgKnownSubject = NULL;

    // init trust data
    WINTRUST_DATA trust_data = {0};
    trust_data.cbStruct = sizeof(trust_data);
    trust_data.dwUIChoice = WTD_UI_NONE;
    trust_data.fdwRevocationChecks = WTD_REVOKE_NONE;
    trust_data.dwUnionChoice = WTD_CHOICE_FILE;
    trust_data.dwStateAction = WTD_STATEACTION_VERIFY;
    trust_data.hWVTStateData = NULL;
    trust_data.pwszURLReference = NULL;
    trust_data.dwProvFlags = WTD_SAFER_FLAG;
    trust_data.dwUIContext = 0;
    trust_data.pFile = &file_data;

    // verify trust
    GUID guid_action = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    LONG status = WinVerifyTrust(NULL, &guid_action, &trust_data);

    // clean up
    trust_data.dwStateAction = WTD_STATEACTION_CLOSE;
    WinVerifyTrust(NULL, &guid_action, &trust_data);

    // check status
    if (status == ERROR_SUCCESS) {
        info->is_signed = tb_true;
        info->is_trusted = tb_true;
    } else if (status == TRUST_E_NOSIGNATURE) {
        return tb_true;
    } else if (status == TRUST_E_EXPLICIT_DISTRUST || status == TRUST_E_SUBJECT_NOT_TRUSTED) {
        info->is_signed = tb_true;
        info->is_trusted = tb_false;
    } else {
        return tb_false;
    }

    // extract signer name
    if (info->is_signed) {
        HCERTSTORE hStore = NULL;
        HCRYPTMSG hMsg = NULL;
        DWORD dwEncoding = 0;
        DWORD dwContentType = 0;
        DWORD dwFormatType = 0;
        PCMSG_SIGNER_INFO pSignerInfo = NULL;
        PCCERT_CONTEXT pCertContext = NULL;
        BOOL bResult = FALSE;

        bResult = CryptQueryObject(CERT_QUERY_OBJECT_FILE,
                                   wide_path,
                                   CERT_QUERY_CONTENT_FLAG_PKCS7_SIGNED_EMBED,
                                   CERT_QUERY_FORMAT_FLAG_BINARY,
                                   0,
                                   &dwEncoding,
                                   &dwContentType,
                                   &dwFormatType,
                                   &hStore,
                                   &hMsg,
                                   NULL);

        if (bResult) {
            DWORD cbSignerInfo = 0;
            if (CryptMsgGetParam(hMsg, CMSG_SIGNER_INFO_PARAM, 0, NULL, &cbSignerInfo)) {
                pSignerInfo = (PCMSG_SIGNER_INFO)tb_malloc(cbSignerInfo);
                if (pSignerInfo) {
                    if (CryptMsgGetParam(hMsg, CMSG_SIGNER_INFO_PARAM, 0, (void*)pSignerInfo, &cbSignerInfo)) {
                        CERT_INFO certInfo;
                        certInfo.Issuer = pSignerInfo->Issuer;
                        certInfo.SerialNumber = pSignerInfo->SerialNumber;

                        pCertContext = CertFindCertificateInStore(hStore,
                                                                  (X509_ASN_ENCODING | PKCS_7_ASN_ENCODING),
                                                                  0,
                                                                  CERT_FIND_SUBJECT_CERT,
                                                                  (PVOID)&certInfo,
                                                                  NULL);

                        if (pCertContext) {
                            tb_wchar_t wName[256] = {0};
                            if (CertGetNameStringW(pCertContext,
                                                   CERT_NAME_SIMPLE_DISPLAY_TYPE,
                                                   0,
                                                   NULL,
                                                   wName,
                                                   256)) {
                                WideCharToMultiByte(CP_UTF8, 0, wName, -1, info->signer_name, sizeof(info->signer_name), NULL, NULL);
                            }
                            CertFreeCertificateContext(pCertContext);
                        }
                    }
                    tb_free(pSignerInfo);
                }
            }
        }

        if (hStore) CertCloseStore(hStore, 0);
        if (hMsg) CryptMsgClose(hMsg);
    }

    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get the file signature info
 *
 * local info = winos.file_signature(filepath)
 * {
 *      is_signed = true,
 *      is_trusted = true,
 *      signer_name = "Microsoft Corporation"
 * }
 */
tb_int_t xm_winos_file_signature(lua_State *lua) {
    
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const *filepath = luaL_checkstring(lua, 1);
    tb_check_return_val(filepath, 0);

    // get signature info
    tb_file_signature_info_t info = {0};
    if (tb_file_get_signature_info(filepath, &info)) {
        lua_newtable(lua);
        lua_pushstring(lua, "is_signed");
        lua_pushboolean(lua, info.is_signed);
        lua_settable(lua, -3);

        lua_pushstring(lua, "is_trusted");
        lua_pushboolean(lua, info.is_trusted);
        lua_settable(lua, -3);

        if (info.is_signed) {
            lua_pushstring(lua, "signer_name");
            lua_pushstring(lua, info.signer_name);
            lua_settable(lua, -3);
        }
        return 1;
    }
    return 0;
}
