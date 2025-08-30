public class Main {
    public native float[] helloWorld(int num_vectors);

    // Runs when the class is loaded (aka immediately after compilation)
    static {
        System.loadLibrary("native");
    }

    public static void main(String[] args) {
        System.out.println("Running!");
        int num_vectors = 10000000;
        int size = num_vectors * 3;
        float[] output = new Main().helloWorld(num_vectors);
        //System.out.println("\nHi from Java! Here are the received array values:");
        //for (int i = 0; i < size; i++) {
        //    System.out.println(output[i]);
        //}

        System.out.println("\nProgram finished!");
    }
}