public class Main {
    public native double[] test();

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
