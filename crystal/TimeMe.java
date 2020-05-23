import java.util.Random;

public class TimeMe {

    private static Random rand = new Random();

    public static int myRandom(int upTo) {
        return rand.nextInt(upTo) + 1;
    }

    public static void main (String[] args) throws Exception{
        long start = System.nanoTime();
        for (int i=1; i < 100000000; i++) {
            myRandom(42);
        }
        long end = System.nanoTime();
        System.out.println("Completed in " + (end - start)/1000000000.0 + " seconds!");
    }

}
