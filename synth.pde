class Synth {  
  AudioContext ac;
  
  Gain g;
  
  SamplePlayer sp;
  
  int sample_num = -1;
  int rate = -1; // number of times sample is played per bar
  boolean[] decay; // whether sample is played or not
  
  Synth(AudioContext ac, Gain g) {
    this.ac = ac;
    this.g = g;
    
    sample_num = int(random(NUM_SAMPLES));
    
    sp = new SamplePlayer(ac, GetSample(sample_num));
    sp.setLoopType(SamplePlayer.LoopType.NO_LOOP_FORWARDS);
    sp.setKillOnEnd(false); // wish to play multiple times
    
    //int relFreq = int(relFreqs.get(sample_num) + random(4) - 1);
    //rate = int(pow(2, constrain(relFreq, 0, int(log(maxBeats) / log(2)))));
    rate = int(random(1, maxBeats));
    
    decay = new boolean[maxBeats];
    for (int j = 0; j < maxBeats; j++) {
      decay[j] = random(1) > 0.5;
    }
        
    g.addInput(sp);
  }
  
  String getEncoding() {
    String encoding = "";
    
    encoding += String.format("%1$" + LOG_NUM_SAMPLES + "s", Integer.toBinaryString(sample_num)).replace(' ', '0');
    
    encoding += String.format("%1$" + LOG_MAX_BEATS + "s", Integer.toBinaryString(rate)).replace(' ', '0');
    
    for (int i = 0; i < decay.length; i++) encoding += decay[i] ? "1" : "0";
    
    return encoding;
  }
  
  void decodeSynth(String encoding) {
    int idx = 0;
    
    sample_num = Integer.parseInt(encoding.substring(0, LOG_NUM_SAMPLES), 2);
    if (sample_num >= sampleList.size()) sample_num = int(random(sampleList.size()));
    sp.setSample(GetSample(sample_num));
    idx += LOG_NUM_SAMPLES;
    
    rate = Integer.parseInt(encoding.substring(idx, idx + LOG_MAX_BEATS), 2);
    rate = rate == 0 ? 1 : rate;
    idx += LOG_MAX_BEATS;
    
    for (int i = 0; i < decay.length; i++) decay[i] = encoding.charAt(idx + i) == '1' ? true : false;
  }
  
  void beatChanged(int beat) {
    if (beat % rate == 0 && decay[beat / rate]) {
      sp.setToLoopStart();
      sp.start();
    }; 
  }
  
  void changeSample(int idx) {
    sp.setSample(GetSample(idx)); 
  }
  
  void randomise() {
    sample_num = int(random(NUM_SAMPLES));
    changeSample(sample_num);
    
    //int relFreq = int(relFreqs.get(sample_num) + random(4) - 1);
    //rate = int(pow(2, constrain(relFreq, 0, int(log(maxBeats) / log(2)))));
    rate = int(random(1, maxBeats));

    decay = new boolean[maxBeats];
    for (int j = 0; j < maxBeats; j++) {
      decay[j] = random(1) > 0.5;
    }
  }
  
  void Destroy() {
    // clean up resources
    sp.kill();
  }
}
