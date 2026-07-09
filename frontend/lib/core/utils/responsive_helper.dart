class Responsive {
  static bool isMobile(double w)=>w<600;
    static bool isTablet(double w)=>w<600 && w<1100;
    static bool isDesktop(double w)=>w<600 && w>1100;


}