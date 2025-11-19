public class Main {
    public native double[] test();

    // Runs when the class is loaded (aka immediately after compilation)
    static {
        System.loadLibrary("native");
    }

    public static void main(String[] args) {
        System.out.println("Running!");
        double[] output = new Main().test();
        for (double color_value : output) {
            System.out.println(color_value);
        }
        System.out.println("\nProgram finished!");
    }
}
