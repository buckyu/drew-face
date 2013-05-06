This is v1.1 of FaceDetect, the image recognition component of selected smiles.

Version History:

1.2 - added new API for stitching photos
1.1 - fixed a bug that causes a crash if the image is missing EXIF data
1.0 - initial release

A sample C# application that utilizes the library is provided.  The sample application's expected output is provided below.  You should be able to compile and run the sample application out of the box with Visual Studio 2012 for Windows Desktop.

Installation Notes:

This software package comprises a wide variety of languages and technologies for high performance.  All of the distributable files are in the "payload" directory.

1.  Your .NET application must have references to these two DLLs:

FaceDetect.dll
FaceDetectInternalManaged.dll

2.  There are a wide variety of other DLLs in the payload folder that are also required to be present.  They must be placed in some location that Windows will find them.  We recommend placing them in the same directory as your application binary, but there are a wide variety of options available to you including the c:\windows directory.  See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682586(v=vs.85).aspx for more information on acceptable DLL paths.

3.  XML files.  These XML files must be placed in the application's current working directory.

Usage notes:

1.  Create a GeometryType with an absolute path to a JPG format color image.  The image must be high-resolution and well-lit.
2.  Call FaceDetector.detectFaces as shown in the sample application
3.  The GeometryType will be populated with a wide variety of data including face, mouth, and teeth detection information.

Troubleshooting:

Q: After linking against FaceDetect/FaceDetectInternalManaged, my application fails to launch!
A: Please check that all the DLLs in the payload are properly installed.  You can use Process Monitor (http://technet.microsoft.com/en-us/sysinternals/bb896645.aspx) to determine where the application is searching for DLL files.

Q: After calling detectFaces, I get an unhandled exception and the application crashes.
A: Please check that the XML files are available in the working directory.  You can use Process Monitor to determine where the application is searching for XML files.

Q: The output for some images seems off.
A: Our library of sample images is limited.  Please send us new samples to improve our test set.

For further technical troubleshooting, please e-mail developer@drewcrawfordapps.com.



Sample app expected output:

    Press enter to detect an image.

    Filename = C:\test.jpg
    processing image C:\test.jpgabout to exif
    exif complete
    begin opencv
    finding teeth area
    2
    solution of size 14
    List value is System.Collections.Generic.List`1[FaceDetect.Point]
    1250.046,1920.627
    1252.723,1920.627
    1298.228,1923.304
    1244.692,2014.314
    1148.329,2057.142
    1035.905,2070.526
    1025.198,2070.526
    968.9863,2065.172
    894.0371,2057.142
    856.5625,2027.698
    853.8857,2025.021
    848.5322,2011.637
    840.502,1982.193
    840.502,1968.809

