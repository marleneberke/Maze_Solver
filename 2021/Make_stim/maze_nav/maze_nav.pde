BufferedReader reader;
String line;
PImage img;

void setup(){
  img = loadImage("7by7_maze4_big.jpg");
  //img.resize(800, 800); // only use resize on the big mazes
  //size(1200, 1000); //600, 500, //1200, 1000
  size(1200, 1000);
  
  reader = createReader("path.txt");
}


int start_x = 27;//34 for 15by15s //was 39 //25 for (10by10)
int start_y = 6;//14 for 15by15s //was 15 //4 for (10by10)
int factor = 35;//25 for (15_by_15_seed4) //47 for (7by7); //35 (10_by_10)
int time_scale_factor = 10; //10

void draw() { 
  background(0);
  
  image(img, 50, 25);
  
  try {
    line = reader.readLine();  //this line should have the computation time
  } catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  if (line == null){
    //stop reading becasue file is empty
    noLoop();
  } else {
    float delay_length = float(line);
    println(int(delay_length*time_scale_factor));
    if (delay_length < 0) {
      noLoop();
    } else {
      delay(int(delay_length*time_scale_factor));
    }
  }
  
  try {
    line = reader.readLine();  //this line                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               should be the coordinate
  } catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  int[] list = int(splitTokens(line, "Coordinate(), "));
  //fill(0, 190, 255); //blue
  //fill(102, 255, 0); //green
  fill(255, 255, 0); //yellow
  circle(2.7*factor*list[1] + start_x, 2.65*factor*list[0] + start_y, 26); //2.05 and 1.96 //(1.48 and 1.46 for 15by15s)
  fill(0, 0, 0); //black
  circle(2.7*factor*list[1] + start_x, 2.65*factor*list[0] + start_y, 10); //2.05 and 2.04 for 15_by_15_maze_4
  
} 
