BufferedReader reader;
String line;
PImage img;

void setup(){
  img = loadImage("maze.jpg");
  size(600, 500);
  
  reader = createReader("path.txt");
}


int start_x = 45;
int start_y = 20;
int factor = 7;

void draw() { 
  background(0);
  
  image(img, 50, 25);
  try {
    line = reader.readLine();
    
  } catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  
  
  
  
  if (line == null){
    //stop reading becasue file is empty
    noLoop();
  } else {
    int[] list = int(splitTokens(line, "Coordinate(), "));
    fill(204, 102, 0);
    rect(2*factor*list[1] + start_x, 2*factor*list[0] + start_y, 5, 5);
  }
  
  delay(350);
  
} 
