public class Main {
    public native Color[][] test();

    // Runs when the class is loaded (aka immediately after compilation)
    static {
        System.loadLibrary("native");
    }

    public static void main(String[] args) {
        System.out.println("Running!");
        new Main().test();
        System.out.println("\nProgram finished!");
    }
}

class Color {
    public double r;
    public double g;
    public double b;
    public Color(double r, double b, double g) {
        this.r = r;
        this.g = g;
        this.b = b;
    }
}