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

            if (geometryType.fileName.Length > 0)
            {
                Console.WriteLine("List value is {0}", geometryType.teethArea.ToString());
                foreach (Point p in geometryType.teethArea)
                {

                    Console.WriteLine("{0},{1}", p.x, p.y);
                }

                String mouthImage = "C:\\mouth.jpg";
                String result = FaceDetect.FaceDetector.stitchFace(geometryType, mouthImage);
                Console.WriteLine("Result written to {0}", result);
            }
            else
            {
                Console.WriteLine("Couldn't find a face and/or mouth");
                Console.WriteLine("It's also possible that a jpeg image wasn't provided.");
            }

            geometryType = new FaceDetect.GeometryType();
            geometryType.fileName = "C:\\test.png";
            FaceDetect.FaceDetector.detectFaces(geometryType);

            if (geometryType.fileName.Length > 0)
            {
                Console.WriteLine("List value is {0}", geometryType.teethArea.ToString());
                foreach (Point p in geometryType.teethArea)
                {

                    Console.WriteLine("{0},{1}", p.x, p.y);
                }

                String mouthImage = "C:\\mouth.jpg";
                String result = FaceDetect.FaceDetector.stitchFace(geometryType, mouthImage);
                Console.WriteLine("Result written to {0}", result);
            }
            else
            {
                Console.WriteLine("Couldn't find a face and/or mouth");
                Console.WriteLine("It's also possible that a jpeg image wasn't provided.");
            }
            
            Console.ReadLine();
        }
    }
}
