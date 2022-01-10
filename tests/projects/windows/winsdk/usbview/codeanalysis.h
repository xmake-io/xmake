/*++

Copyright (c) 1997-2011 Microsoft Corporation

Module Name:

    CODEANALYSIS.H

Abstract:

    This header file is used for supressing fxcop errors which are not applicable

Environment:

    user mode

Revision History:

    08-11-11 : created

--*/

#pragma once

#if CODE_ANALYSIS

/*****************************************************************************
  C O D E  A N A L Y S I S  S U P P R E S S I O N S
 *****************************************************************************/

using namespace System::Diagnostics::CodeAnalysis;

namespace Microsoft
{
    namespace Kits 
    {
        namespace Samples
        {
            namespace Usb
            {
                // Justification : C++ Compiler cannot enforce ClsCompliant 
                [module: SuppressMessage("Microsoft.Design", "CA1014:MarkAssembliesWithClsCompliant")]

                // Justification : The naming of the following types are based on native USB types
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType", MessageId="Bos")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.Hub30DescriptorType.#HubHdrDecLat", MessageId="Hdr")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.MachineInfoType.#UvcMajorSpecVersion", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.MachineInfoType.#UvcMinorSpecVersion", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.MachineInfoType.#UvcMinorVersion", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.MachineInfoType.#UvcMajorVersion", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceClassDetailsType.#UvcVersion", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#BNumDeviceCaps", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#UsbDispContIdCapExtDescriptor", MessageId="Disp")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#BosDescriptor", MessageId="Bos")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.NodeConnectionInfoExType.#IProductStringDescEn", MessageId="Desc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceConfigurationType.#OtgDescriptor", MessageId="Otg")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceConfigurationType.#OtgError", MessageId="Otg")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceConfigurationType.#IadError", MessageId="Iad")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceConfigurationType.#IadDescriptor", MessageId="Iad")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceIADDescriptorType.#StringDesc", MessageId="Desc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceInterfaceDescriptorType.#BNumEndpoints", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceInterfaceDescriptorType.#StringDesc", MessageId="Desc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceInterfaceDescriptorType.#WNumClasses", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.NodeConnectionInfoExStructType.#NumOfOpenPipes", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.NodeConnectionInfoExStructType.#SpeedStr", MessageId="Str")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConfigurationDescriptorType.#ConfStringDesc", MessageId="Desc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConfigurationDescriptorType.#AttributesStr", MessageId="Str")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConfigurationDescriptorType.#ConfigDescError", MessageId="Desc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConfigurationDescriptorType.#BNumInterfaces", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UvcViewAll", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UvcViewAll.#UvcView", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UsbDispContIdCapExtDescriptorType", MessageId="Disp")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDispContIdCapExtDescriptorType.#ContainerIdStr", MessageId="Str")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConnectionStatusType.#DeviceCausedOvercurrent", MessageId="Overcurrent")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceQualifierDescriptorType.#NumConfigurations", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceQualifierDescriptorType.#DeviceNumConfigError", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceDescriptorType.#NumConfigurations", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceType.#BosDescriptor", MessageId="Bos")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UvcViewType", MessageId="Uvc")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceHidDescriptorType.#BNumDescriptors", MessageId="Num")];
                [module: SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#HubInformationEx")];
                [module: SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#HubInformationEx")];
                [module: SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceConfigurationType.#PreReleaseError", MessageId="PreRelease")];
                [module: SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbHCPowerStateType.#CanWakeUp", MessageId="WakeUp")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbSuperSpeedExtensionDescriptorType.#BmAttributes", MessageId="Bm")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbUsb20ExtensionDescriptorType.#BmAttributes", MessageId="Bm")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.HubNodeType.#UsbMiParent", MessageId="Mi")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#HwId", MessageId="Hw")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.HostControllerType.#HwId", MessageId="Hw")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UsbDeviceOTGDescriptorType", MessageId="OTG")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceOTGDescriptorType.#BmAttributes", MessageId="Bm")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.HubNodeInformationType.#MiParentNumberOfInterfaces", MessageId="Mi")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.NodeConnectionInfoExType.#IProductStringDescEn", MessageId="En")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="type", Target="Microsoft.Kits.Samples.Usb.UsbDeviceIADDescriptorType", MessageId="IAD")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbConfigurationDescriptorType.#BmAttributes", MessageId="Bm")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#HwId", MessageId="Hw")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceQualifierDescriptorType.#BcdUSB", MessageId="USB")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceDescriptorType.#CdDevice", MessageId="Cd")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceDescriptorType.#CdUSB", MessageId="USB")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceDescriptorType.#CdUSB", MessageId="Cd")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceType.#HwId", MessageId="Hw")];
                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceHidDescriptorType.#BcdHID", MessageId="HID")];
                [module: SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#HubCapabilityEx")]
                [module: SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#HubCapabilityEx")]
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.HubCapabilitiesExType.#HubIsMultiTt", MessageId="Multi")]
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", Scope="member", Target="Microsoft.Kits.Samples.Usb.HubCapabilitiesExType.#HubIsMultiTtCapable", MessageId="Multi")]

                [module: SuppressMessage("Microsoft.Naming", "CA1709:IdentifiersShouldBeCasedCorrectly", MessageId="usbview")];
                [module: SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId="usbview")];

                // Justification: The version of XSD which is used to generate the objects does not support Collections. 
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#UsbSuperSpeedExtensionDescriptor")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#UsbUsb20ExtensionDescriptor")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#UnknownDescriptor")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbBosDescriptorType.#UsbDispContIdCapExtDescriptor")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#UsbDevice")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#DeviceConfiguration")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#NoDevice")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.ExternalHubType.#ExternalHub")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.NodeConnectionInfoExStructType.#Pipe")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbHCPowerStateMappingType.#PowerMap")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#NoDevice")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#ExternalHub")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.RootHubType.#UsbDevice")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceType.#DeviceConfiguration")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UvcViewType.#UsbTree")];
                [module: SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Scope="member", Target="Microsoft.Kits.Samples.Usb.UsbDeviceHidDescriptorType.#OptionalDescriptor")];
                };
        };
    };
};

#endif
