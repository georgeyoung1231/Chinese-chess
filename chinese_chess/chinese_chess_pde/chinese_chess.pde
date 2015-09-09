import processing.serial.*;
import gausstoys.core.*;
import ddf.minim.*;

AudioPlayer player;
Minim minim;//audio context
GaussSense gs;

PImage bg_img;
PImage img;
int row = 4, col = 8, dist = 125, chess_size = 120, chess_num = row*col;
int tags[][] = {{73, 12}, {105, -100}, {-119, 111}, {-87, -82}, {-119, -65}, {9, 26}, {-103, 55}, // Red team from rank 0 to 6
                {89, 48}, {-55, -68}, {-39, 74}, {-7, -118}, {-23, -98}, {-39, 90}, {57, -106}};  // Blue team from rank 0 to 6
//int tags[][] = {{-103, 55}, {9, -26}, {-119, -65}, {-87, -82}, {-119, 111}, {105, -100}, {73,12}, // Red team from rank 6 to 0
//                {57, -106}, {-39, 90}, {-23, -98}, {-7, -118}, {-39, 74}, {-55, -68}, {89, 48}}; // Blue team from rank 6 to 0
PVector start = new PVector(4,129);
PVector board_pos[][] = new PVector[row][col];
String rank_img_map[] = {};
boolean isOnStage = false;
String direction = "";
boolean victory = false;

int token_num = 14;
GaussToken TokenOnStage = new GaussToken(false, 0);
GaussToken GTList[] = new GaussToken[token_num];
class GaussToken{
  int rank;
  boolean team;
  int tag[] = new int[2];
  GaussToken(int rank, boolean team, int tag1, int tag2){
    this.team = team;
    this.rank = rank;
    this.tag[0] = tag1;
    this.tag[1] = tag2;
  }
}

class Board{
  PVector pos;
  boolean isEmpty;
  Chess who;
}

class Chess{
  boolean isDead;
  PVector pos;
  int rank;
  boolean flip;
  boolean team;
  public Chess(boolean team, int rank){
    this.team = team;
    this.isDead = false;
    this.flip = false;
    this.rank = rank;
    this.pos = null;
  }
  public void setPosition(PVector pos){
    this.pos = pos;
  }
  public void flip(boolean team, int rank){
    if(this.team == team && this.rank == rank){
      this.flip = true;
    }
  }
}
Chess chessList[] = new Chess[chess_num];
Board boardList[][] = new Board[row][col];
void setup() {
  size(1000, 625);
  minim = new Minim(this);
  
  GaussSense.printSerialPortList();
  //Initialize the GaussSense//Initialize the GaussSense
  gs = new GaussSense(this, GaussSense.GSType.GAUSSSENSE_STAGE, Serial.list()[Serial.list().length - 1], 115200);
  bg_img = loadImage("ChineseChess-01.jpg");
  gs.setVibrator(false);
  int rank_arr[] = {0,0,0,0,0,1,1,2,2,3,3,4,4,5,5,6};
  
  for (int i = 0; i < rank_arr.length; i++) {
    chessList[i] = new Chess(false, rank_arr[i]);
    chessList[rank_arr.length + i] = new Chess(true, rank_arr[i]);
  }
  for (int i = 0; i < row; i++) {
    for (int j = 0; j < col; j++) {
      boardList[i][j] = new Board();
      boardList[i][j].pos = new PVector(start.x+dist*j, start.y+dist*i);
      boardList[i][j].isEmpty = false;
      // randomly pick chess who doesn't have position to put in this grid
      int random_num;
      do{
        random_num = (int)random(chess_num);
      }while(chessList[random_num].pos != null);
      chessList[random_num].setPosition(new PVector(i,j));
      boardList[i][j].who = chessList[random_num];
    }
  }
  for (int i = 0; i < token_num; i++) {
    GTList[i] = new GaussToken(,,)
  }
}

void draw() {
  background(0);
  image(bg_img, 0, 0, 1000, 626);
  float thld = 5; //Unit: Gauss
  //Get bipolar midpoint data
  int upsampleFactor = 5;
  gs.setUpsampledData2D(this.width, this.height, upsampleFactor);
  GData pBipolarMidpoint = gs.getBipolarMidpoint(thld);
  
  if(gs.isTagOn()) {
    // GaussStage 
    int[] tag = gs.getTagID();
    String str = "Tag: "+tag[0]+", "+tag[1]+", "+tag[2]+", "+tag[3]+", "+tag[4];
    println(str);
    float angleInRad = (float) pBipolarMidpoint.getAngle(); //Get the angle of roll. Unit: Rad
    int angleInDegree = (int) degrees(angleInRad); //Turn the rad into degree
    angleInDegree = angleInDegree+180; // map degree to 0~360
    println(angleInDegree);
    
    if (angleInDegree > 225 && angleInDegree < 315)
      direction = "up";
    else if (angleInDegree > 315 || angleInDegree < 45)
      direction = "right";
    else if (angleInDegree > 45 && angleInDegree < 135)
      direction = "down";
    else 
      direction = "left";
    println(angleInDegree + ":" + direction);
//    println(OnStage(tag));
    int rank = OnStage(tag);
    if(rank > 6){
      curent_chess.rank = 6 - (rank - 7);
      curent_chess.team = true;
    }
    else{
      curent_chess.rank = 6 - rank;
      curent_chess.team = false;
    }
    
    flipRankChess(curent_chess);
    isOnStage = true;
    
  }else if(isOnStage == true){
    println("jump");
    println(direction);
    isOnStage = false;
    for(int i = 0; i < chess_num; i++){
      if(chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
        if(direction == "up"){
          chess_move(chessList[i], new PVector(-1, 0));
        }
        else if(direction == "down"){
          chess_move(chessList[i], new PVector(1, 0));
        }
        else if(direction == "left"){
          chess_move(chessList[i], new PVector(0, -1));
        }
        else if(direction == "right"){
          chess_move(chessList[i], new PVector(0, 1));
        }
      }
    }
    
  }
  
  for(int i = 0; i < chess_num; i++){
    int x = (int)chessList[i].pos.x, y = (int)chessList[i].pos.y;
    if(!chessList[i].flip){
          pushStyle();
          img = loadImage("ChineseChess-000.png");
          image(img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
          popStyle();
      }
    else if(!chessList[i].isDead){
          
          pushStyle();
          int team = chessList[i].team?1:0;
          String str = "ChineseChess-" + team + chessList[i].rank +".png";
          img = loadImage(str);
          image(img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
          popStyle();
          if(gs.isTagOn() && chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
            if(direction == "right"){
              img = loadImage("ChineseChessArrow-right.png");
            }else if(direction == "up"){
              img = loadImage("ChineseChessArrow-up.png");
              
            }else if(direction == "left"){
              img = loadImage("ChineseChessArrow-left.png");
            }
            else{
              img = loadImage("ChineseChessArrow-down.png");
            }
            image(img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
          }

          
    }
  }
   
  if(checkWin() && !victory){
      player = minim.loadFile("victory.mp3", 2048);
      player.play();
      victory = true;
  }
}

boolean chess_move(Chess who, PVector direction){
  // new possible position (x, y)
  int x = (int)(who.pos.x + direction.x);
  int y = (int)(who.pos.y + direction.y);
  
  if(x < row && y < col && x >= 0 && y >= 0){
    // inside the board
    if(boardList[x][y].isEmpty){
      // next grid is empty/movable
      player = minim.loadFile("marching.mp3", 2048);
      player.play();
      boardList[(int)who.pos.x][(int)who.pos.y].isEmpty = true;
      boardList[(int)who.pos.x][(int)who.pos.y].who = null;
      who.pos.x = x;
      who.pos.y = y;
      boardList[x][y].who = who;
      boardList[x][y].isEmpty = false;
      return true;
    }
    else if((boardList[x][y].who!=null) && chess_attack(who, boardList[x][y].who)){
      // attack successfully
      player = minim.loadFile("eat.wav", 2048);
      player.play();
      boardList[(int)who.pos.x][(int)who.pos.y].isEmpty = true;
      boardList[(int)who.pos.x][(int)who.pos.y].who = null;
      who.pos.x = x;
      who.pos.y = y;
      boardList[x][y].who = who;
      boardList[x][y].isEmpty = false;
      println("team: " + boardList[x][y].who.team + "rank: " + boardList[x][y].who.rank + "is killed!");
      gs.setVibrator(true);
      delay(1000);
      gs.setVibrator(false);
      return true;
    }
    else{
      return false;
    }
  }
  return false;
}

boolean chess_attack(Chess who, Chess enemy){
  // return attack success or not
  if (who.flip && enemy.flip && who.team != enemy.team) {
    if ((who.rank >= enemy.rank) && !(who.rank == 6 && enemy.rank == 0)) {
      // kill the smaller except king cannot kill the smallest
      enemy.isDead = true;
      return true;
    }
    else if (who.rank == 0 && enemy.rank == 6) {
      // kill the king
      enemy.isDead = true;
      return true;    
    }
    else {
      return false;
    }
  }
  return false;
}

// flip all chesses with same rank
void flipRankChess (selected_chess op) {
  for (int i = 0; i < chess_num; i++) {
    if (chessList[i].rank == op.rank && chessList[i].team == op.team) {
      if (!chessList[i].flip) {
        player = minim.loadFile("flip.wav", 2048);
        player.play();
        chessList[i].flip = true;
      }
    }
  }
}

// Return the found index of tags array
int OnStage (int id[]) {
  for (int i = 0; i < tags.length; i++) {
    if (id[0] == tags[i][0] && id[1] == tags[i][1]){
      return i;
    }
  }
  return 0;
}

// Victory judgement
boolean checkWin(){
  boolean team0_win = true, team1_win = true;
  for(int i = 0; i < chess_num; i++){
    if(!chessList[i].isDead && !chessList[i].team){
      team0_win = false;
    }else if(!chessList[i].isDead && chessList[i].team){
      team1_win = false;
    }
  }
  return team0_win || team1_win;
}

void keyPressed(){
  if(key == '0'){
    curent_chess.rank = 0;
    flipRankChess(curent_chess);
  }else if(key == '1'){
    curent_chess.rank = 1;
    flipRankChess(curent_chess);
  }else if(key == '2'){
    curent_chess.rank = 2;
    flipRankChess(curent_chess);
  }else if(key == '3'){
    curent_chess.rank = 3;
    flipRankChess(curent_chess);
  }else if(key == '4'){
    curent_chess.rank = 4;
    flipRankChess(curent_chess);
  }else if(key == '5'){
    curent_chess.rank = 5;
    flipRankChess(curent_chess);
  }else if(key == '6'){
    curent_chess.rank = 6;
    flipRankChess(curent_chess);
  }else if(key == 't'){
    curent_chess.team = !curent_chess.team;
    println(curent_chess.team);
  }else if(key == CODED){
    if(keyCode == RIGHT){
      println("right");
      for(int i = 0; i < chess_num; i++){
        if(chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
          chess_move(chessList[i], new PVector(0, 1));
        }
      }
    }else if(keyCode == LEFT){
      for(int i = 0; i < chess_num; i++){
        if(chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
          chess_move(chessList[i], new PVector(0, -1));
        }
      }
    }
    else if(keyCode == UP){
      for(int i = 0; i < chess_num; i++){
        if(chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
          chess_move(chessList[i], new PVector(-1, 0));
        }
      }
    }
    else if(keyCode == DOWN){
      for(int i = 0; i < chess_num; i++){
        if(chessList[i].rank == curent_chess.rank && chessList[i].team == curent_chess.team){
          chess_move(chessList[i], new PVector(1, 0));
        }
      }
    }
  }
} 