using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FaceDetect
{
    public class Point {
        public float x;
        public float y;
    }
    public class Rect {
        public float x;
        public float y;
        public float width;
        public float height;
    }
    public class GeometryType
    {
        public List<Point> teethArea;
        public String fileName;
        public Rect mouthArea;
        public Rect faceArea;
        public int teethWidth;
    }
}
