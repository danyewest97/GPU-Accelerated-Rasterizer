public class Main {
    public native double[] test(int width, int height);

    // Runs when the class is loaded (aka immediately after compilation)
    static {
        System.loadLibrary("native");
    }

    public static void main(String[] args) {
        System.out.println("Running!");
        double[] output = new Main().test(20, 20);
        for (double color_value : output) {
            //System.out.println(color_value);
        }
        System.out.println("\nProgram finished!");
    }
}
