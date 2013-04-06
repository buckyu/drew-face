using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FaceDetect;

namespace ConsoleApplication2
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Press enter to detect an image.");
            Console.ReadLine();

            FaceDetect.GeometryType geometryType = new FaceDetect.GeometryType();
            geometryType.fileName = "C:\\test.jpg";
            FaceDetect.FaceDetector.detectFaces(geometryType);

            Console.WriteLine("List value is {0}", geometryType.teethArea.ToString());
            Console.ReadLine();
        }
    }
}
