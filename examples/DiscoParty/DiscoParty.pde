import processing.serial.*;
import controlP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput audioin;

FFT leftFft;
FFT rightFft;

ControlP5 controlP5;

float Sensitivity = 10;  // amplification value
float Smoothing = 1;     // how fast things die off
float colorSpeed = .05;  // How much the colors flicker

String[] cliOptions = {"--colorspeed", "--devices", "-h", "--help", "--sensitivity", "--smoothing", "--spacing"};
ArrayList<BlinkyTape> bts = new ArrayList<BlinkyTape>();

int btSpacing = 15;
float colorAngle = 0;
int numberOfLEDs = 60;

// A bunch of dynamic pulsers
ArrayList<Pulser> leftPulsers = new ArrayList<Pulser>();
ArrayList<Pulser> rightPulsers = new ArrayList<Pulser>();

Burst burst;

DiscoPartyParticle logo;

SerialSelector s;

boolean validOption(String option) {
  for (int i = 0; i < cliOptions.length; i++) {
     if (option.equals(cliOptions[i])) {
       return true; 
     }
  }
  return false;
}

boolean isHelp(String option) {
  return option.equals("-h") || option.equals("--help");
}

void printHelp() {
  println("-h, --help:            show this help info");
  println("--colorspeed value:    set colorspeed to specified float value");
  println("--devices device_list: output to specified devices");
  println("--sensitivity value:   set sensitivity to specified float value");
  println("--smoothing value:     set smoothing to specified float value");
  println("--spacing value:       set BlinkyTape spacing to specified int value");
}

void processArguments() {
  if (args == null || args.length == 0) {
    // No args to process
    return;
  }
  
  String currentOption = null;
  for (int i = 0; i < args.length; i++) {
    if (validOption(args[i])) {
      currentOption = args[i];
      continue;
    }
    
    if (currentOption == null) {
      continue; 
    }
    
    if (currentOption.equals("--colorspeed")) {
      colorSpeed = Float.parseFloat(args[i]);
    } else if (currentOption.equals("--devices")) {
      bts.add(new BlinkyTape(this, args[i], numberOfLEDs)); 
    } else if (currentOption.equals("--sensitivity")) {
      Sensitivity = Float.parseFloat(args[i]);
    } else if (currentOption.equals("--smoothing")) {
      Smoothing = Float.parseFloat(args[i]);
    } else if (currentOption.equals("--spacing")) {
      btSpacing = Integer.parseInt(args[i]);
    } 
  }
}

void setup()
{
  if (args.length == 1 && isHelp(args[0])) {
    printHelp();
    exit();
    return;
  }
  
  processArguments();
  
  frameRate(30);
  size(400, 250, P2D);
  
  minim = new Minim(this);
  audioin = minim.getLineIn(Minim.STEREO, 2048);

  leftFft = new FFT(audioin.bufferSize(), audioin.sampleRate());
  leftFft.logAverages(10,1);
  
  rightFft = new FFT(audioin.bufferSize(), audioin.sampleRate());
  rightFft.logAverages(10,1);

  for (int i = 0; i < leftFft.avgSize(); i++) {
    Pulser p = new Pulser();
    p.m_band = i;
    
    if(random(0,1) > .5) {
      p.m_h = 87 + i;
      p.m_s = 100;
      p.m_yv = random(.2,2);
    }
    else {
      p.m_h = 52 + i;
      p.m_s = 100;
      p.m_yv = random(-.2,-2);
    }
    
    p.m_xv = 0;

    leftPulsers.add(p);
  }

  for (int i = 0; i < rightFft.avgSize(); i++) {
    Pulser p = new Pulser();
    p.m_band = i;
    
    if(random(0,1) > .5) {
      p.m_h = 87 + i;
      p.m_s = 100;
      p.m_yv = random(.2,2);
    }
    else {
      p.m_h = 52 + i;
      p.m_s = 100;
      p.m_yv = random(-.2,-2);
    }
    
    p.m_xv = 0;

    rightPulsers.add(p);
  }

  controlP5 = new ControlP5(this);

  controlP5.Slider slider = controlP5.addSlider("Sensitivity")
    .setPosition(40,230)
    .setSize(100,15)
    .setRange(1, 100)
    .setValue(Sensitivity)
    .setId(1);  
  slider.getValueLabel()
      .align(ControlP5.RIGHT,ControlP5.CENTER);
  slider.getCaptionLabel()
      .align(ControlP5.LEFT,ControlP5.CENTER);
      
  slider = controlP5.addSlider("Smoothing")
    .setPosition(150,230)
    .setSize(100,15)
    .setRange(1, 20)
    .setValue(Smoothing)
    .setId(1);  
  slider.getValueLabel()
      .align(ControlP5.RIGHT,ControlP5.CENTER);
  slider.getCaptionLabel()
      .align(ControlP5.LEFT,ControlP5.CENTER);
      
  slider = controlP5.addSlider("colorSpeed")
    .setPosition(260,230)
    .setSize(100,15)
    .setRange(.001, .1)
    .setValue(colorSpeed)
    .setId(1);  
  slider.getValueLabel()
      .align(ControlP5.RIGHT,ControlP5.CENTER);
  slider.getCaptionLabel()
      .align(ControlP5.LEFT,ControlP5.CENTER);
      
  // Don't show SerialSelector if bts was initialized from command line
  if (bts.size() == 0) {
    s = new SerialSelector();  
  }
  
  logo = new DiscoPartyParticle();
  
  burst = new Burst();
}

void draw()
{
  rightFft.forward(audioin.mix);
  leftFft.forward(audioin.mix);
  
  background(0);
  
  logo.draw();

  // Cover the logo up under where the BlinkyTapes are drawn,
  // so they don't pick up the white flashes.
  for(int i = 0; i < bts.size(); i++) {
    float pos = 15 + btSpacing*i;
    
    stroke(0);
    line(pos, 0, pos, height);
  }

  for(Pulser p : leftPulsers) {
    p.draw(leftFft);
  }

  for(Pulser p : rightPulsers) {
    p.draw(rightFft);
  }
  
  for(int i = 0; i < bts.size(); i++) {
    float pos = 15 + btSpacing*i;
    bts.get(i).render(pos, 0, pos, height);
    bts.get(i).update();
    
    stroke(255,100);
    line(pos, 0, pos, height);
  }
  
  colorAngle += colorSpeed;
  
  if(s != null && s.m_chosen) {
    s.m_chosen = false;
    bts.add(new BlinkyTape(this, s.m_port, numberOfLEDs));
    s = null;
  }
}