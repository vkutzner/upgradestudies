#######################################
# Order of execution of various modules
#######################################

#set MaxEvents 30

set ExecutionPath {

  PileUpMerger
  ModifyBeamSpot
  ParticlePropagator
  StatusPid
  GenBeamSpotFilter

  ChargedHadronTrackingEfficiency
  ElectronTrackingEfficiency
  MuonTrackingEfficiency

  ChargedHadronMomentumSmearing
  ElectronEnergySmearing
  MuonMomentumSmearing

  ModifyBeamSpotNoPU
  ParticlePropagatorNoPU
  ChargedHadronTrackingEfficiencyNoPU
  ElectronTrackingEfficiencyNoPU
  MuonTrackingEfficiencyNoPU
  ChargedHadronMomentumSmearingNoPU
  ElectronEnergySmearingNoPU
  MuonMomentumSmearingNoPU
  TrackMergerNoPU
  CalorimeterNoPU
  EFlowMergerNoPU
  FastJetFinderNoPU

  TrackMerger
  Calorimeter
  TrackPileUpSubtractor
  EFlowMerger

  GlobalRho
  Rho
  FastJetFinder
  GenJetFinder
  JetPileUpSubtractor

  NeutrinoFilter
  GenJetFinderNoNu
  GenMissingET

  EFlowChargedMerger
  RunPUPPI
  PuppiJetFinder
  PuppiRho
  PuppiJetPileUpSubtractor
  PuppiMissingET

  PhotonEfficiency
  PhotonIsolation

  ElectronEfficiency
  ElectronIsolation

  MuonEfficiency
  MuonIsolation

  MissingET

  BTaggingLoose
  BTaggingMedium
  BTaggingTight

  TauTagging

  TrackPVSubtractor  
  IsoTrackFilter

  UniqueObjectFinderGJ
  UniqueObjectFinderEJ
  UniqueObjectFinderMJ

  ScalarHT

  PileUpJetID

  PileUpJetIDMissingET

  ConstituentFilter  
  TreeWriter
}

module Merger PileUpJetIDMissingET {
  add InputArray TrackPileUpSubtractor/eflowTracks
  add InputArray MuonMomentumSmearing/muons
  add InputArray PileUpJetID/eflowTowers
  set MomentumOutputArray momentum
}  

module Merger EFlowChargedMerger {
  add InputArray TrackPileUpSubtractor/eflowTracks
  add InputArray MuonMomentumSmearing/muons
  set OutputArray eflowTracks
}

module RunPUPPI RunPUPPI {
#  set TrackInputArray EFlowChargedMerger/eflowTracks
  set TrackInputArray Calorimeter/eflowTracks
  set NeutralInputArray Calorimeter/eflowTowers

  set TrackerEta 2.5

  set OutputArray weightedparticles
}

module FastJetFinder PuppiJetFinder {
  set InputArray RunPUPPI/weightedparticles
  set OutputArray jets

  set JetAlgorithm 6
  set ParameterR 0.4

  set JetPTMin 0.

  # remove pileup again (using it for synchronization)
#  set KeepPileUp 0
}

module FastJetFinder PuppiRho {
  set InputArray RunPUPPI/weightedparticles

  set ComputeRho true
  set RhoOutputArray rho
  
  # area algorithm: 0 Do not compute area, 1 Active area explicit ghosts, 2 One ghost passive area, 3 Passive area, 4 Voronoi, 5 Active area
  set AreaAlgorithm 5

  # jet algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 4
  set ParameterR 0.4
  set GhostEtaMax 5.0
  set RhoEtaMax 5.0
  
  add RhoEtaRange 0.0 2.5
  add RhoEtaRange 2.5 4.0 
  add RhoEtaRange 4.0 5.0

  set JetPTMin 0.0
}

module JetPileUpSubtractor PuppiJetPileUpSubtractor {
  set JetInputArray PuppiJetFinder/jets
  set RhoInputArray PuppiRho/rho
  
  set OutputArray jets
  
  set JetPTMin 10.0
}


###############
# PileUp Merger
###############

module PileUpMerger PileUpMerger {
  set InputArray Delphes/stableParticles

  set OutputArray stableParticles
  set NPUOutputArray NPU

  # Get rid of beam spot from http://red-gridftp11.unl.edu/Snowmass/MinBias100K_14TeV.pileup ...
  set InputBSX 2.44
  set InputBSY 3.39

  # ... and replace it with beam spot from CMSSW files
  set OutputBSX 0.24
  set OutputBSY 0.39

  # pre-generated minbias input file
  set PileUpFile MinBias.pileup

  # average expected pile up
  set MeanPileUp 140
  # spread in the beam direction in m (assumes gaussian)
  set ZVertexSpread 0.053
}

################
# ModifyBeamSpot
################

module ModifyBeamSpot ModifyBeamSpot {
  set ZVertexSpread 0.053
  set InputArray PileUpMerger/stableParticles
  set OutputArray stableParticles
  set PVOutputArray PV
}

module ModifyBeamSpot ModifyBeamSpotNoPU {
  set ZVertexSpread 0.053
  set InputArray Delphes/stableParticles
  set OutputArray stableParticles
  set PVOutputArray PV
}



#################################
# Propagate particles in cylinder
#################################

module ParticlePropagator ParticlePropagator {
  set InputArray PileUpMerger/stableParticles

  set OutputArray stableParticles
  set ChargedHadronOutputArray chargedHadrons
  set ElectronOutputArray electrons
  set MuonOutputArray muons

  # radius of the magnetic field coverage, in m
  set Radius 1.29
  # half-length of the magnetic field coverage, in m
  set HalfLength 3.00

  # magnetic field
  set Bz 3.8
}

module ParticlePropagator ParticlePropagatorNoPU {
  set InputArray Delphes/stableParticles

  set OutputArray stableParticles
  set ChargedHadronOutputArray chargedHadrons
  set ElectronOutputArray electrons
  set MuonOutputArray muons

  # radius of the magnetic field coverage, in m
  set Radius 1.29
  # half-length of the magnetic field coverage, in m
  set HalfLength 3.00

  # magnetic field
  set Bz 3.8

  # remove pileup again (using it for synchronization)
  set KeepPileUp 0
}


####################################
# StatusPidFilter
# This module removes all generated particles
# except electrons, muons, taus, and status==3
####################################

module StatusPidFilter StatusPid {
#    set InputArray Delphes/stableParticles
    set InputArray Delphes/allParticles
    set OutputArray filteredParticles

    set PTMin 1.0
}

#######################
# GenBeamSpotFilter
# Saves a particle intended to represent the beamspot
#######################

module GenBeamSpotFilter GenBeamSpotFilter {
    set InputArray ModifyBeamSpot/stableParticles
    set OutputArray beamSpotParticles

}



####################################
# Charged hadron tracking efficiency
####################################

module Efficiency ChargedHadronTrackingEfficiency {
  set InputArray ParticlePropagator/chargedHadrons
  set OutputArray chargedHadrons

  # add EfficiencyFormula {efficiency formula as a function of eta and pt} - Phase II
  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.0) * (pt > 0.1   && pt <= 1.0)   * (0.71) + \
                                           (abs(eta) <= 1.0) * (pt > 1.0)                  * (0.81) + \
                         (abs(eta) > 1.0 && abs(eta) <= 1.8) * (pt > 0.1   && pt <= 1.0)   * (0.51) + \
                         (abs(eta) > 1.0 && abs(eta) <= 1.8) * (pt > 1.0)                  * (0.58) + \
			 (abs(eta) > 1.8 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.62) + \
                         (abs(eta) > 1.8 && abs(eta) <= 2.5) * (pt > 1.0)                  * (0.71) + \					     
                         (abs(eta) > 2.5)                                                  * (0.00)}
}

module Efficiency ChargedHadronTrackingEfficiencyNoPU {
  set InputArray ParticlePropagatorNoPU/chargedHadrons
  set OutputArray chargedHadrons
    
  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.0) * (pt > 0.1   && pt <= 1.0)   * (0.71) + \
                                           (abs(eta) <= 1.0) * (pt > 1.0)                  * (0.81) + \
                         (abs(eta) > 1.0 && abs(eta) <= 1.8) * (pt > 0.1   && pt <= 1.0)   * (0.51) + \
                         (abs(eta) > 1.0 && abs(eta) <= 1.8) * (pt > 1.0)                  * (0.58) + \
			 (abs(eta) > 1.8 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.62) + \
                         (abs(eta) > 1.8 && abs(eta) <= 2.5) * (pt > 1.0)                  * (0.71) + \					     
                         (abs(eta) > 2.5)                                                  * (0.00)}
}
  
##############################
# Electron tracking efficiency - ID - Phase-II
##############################

module Efficiency ElectronTrackingEfficiency {
  set InputArray ParticlePropagator/electrons
  set OutputArray electrons

  # set EfficiencyFormula {efficiency formula as a function of eta and pt}
  # tracking efficiency formula for electrons

  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (1.0) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0   && pt <= 1.0e2) * (1.0) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0e2)                * (1.0) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (1.0) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0   && pt <= 1.0e2) * (1.0) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0e2)                * (1.0) + \
                         (abs(eta) > 2.5)                                                  * (0.00)}
}

module Efficiency ElectronTrackingEfficiencyNoPU {
  set InputArray ParticlePropagatorNoPU/electrons
  set OutputArray electrons

    # set EfficiencyFormula {efficiency formula as a function of eta and pt}
  # tracking efficiency formula for electrons

  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (0.85) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0   && pt <= 1.0e2) * (0.97) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0e2)                * (0.99) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.85) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0   && pt <= 1.0e2) * (0.90) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0e2)                * (0.95) + \
                         (abs(eta) > 2.5)                                                  * (0.00)}
}


##########################
# Muon tracking efficiency
##########################

module Efficiency MuonTrackingEfficiency {
  set InputArray ParticlePropagator/muons
  set OutputArray muons

  # set EfficiencyFormula {efficiency formula as a function of eta and pt}

  # tracking efficiency formula for muons

  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (0.998) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0)                  * (0.9998) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (1.0) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0)                  * (1.0) + \
                         (abs(eta) > 2.5)                                                  * (0.00)}
}

module Efficiency MuonTrackingEfficiencyNoPU {
  set InputArray ParticlePropagatorNoPU/muons
  set OutputArray muons

    # set EfficiencyFormula {efficiency formula as a function of eta and pt}

  # tracking efficiency formula for muons

  set EfficiencyFormula {                                                    (pt <= 0.1)   * (0.00) + \
                                           (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (0.998) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0)                  * (0.9998) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.98) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0)                  * (0.98) + \
                         (abs(eta) > 2.5)                                                  * (0.00)}
}



########################################
# Momentum resolution for charged tracks
########################################

module MomentumSmearing ChargedHadronMomentumSmearing {
  set InputArray ChargedHadronTrackingEfficiency/chargedHadrons
  set OutputArray chargedHadrons

  # set ResolutionFormula {resolution formula as a function of eta and pt}
  set ResolutionFormula {                  (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (0.015) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0   && pt <= 1.0e1) * (0.013) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0e1 && pt <= 2.0e2) * (0.02) + \
                                           (abs(eta) <= 1.5) * (pt > 2.0e2)                * (0.05) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.015) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0   && pt <= 1.0e1) * (0.015) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0e1 && pt <= 2.0e2) * (0.04) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 2.0e2)                * (0.05)}
}

module MomentumSmearing ChargedHadronMomentumSmearingNoPU {
  set InputArray ChargedHadronTrackingEfficiencyNoPU/chargedHadrons
  set OutputArray chargedHadrons

    # set ResolutionFormula {resolution formula as a function of eta and pt}
  set ResolutionFormula {                  (abs(eta) <= 1.5) * (pt > 0.1   && pt <= 1.0)   * (0.015) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0   && pt <= 1.0e1) * (0.013) + \
                                           (abs(eta) <= 1.5) * (pt > 1.0e1 && pt <= 2.0e2) * (0.02) + \
                                           (abs(eta) <= 1.5) * (pt > 2.0e2)                * (0.05) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1   && pt <= 1.0)   * (0.015) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0   && pt <= 1.0e1) * (0.015) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 1.0e1 && pt <= 2.0e2) * (0.04) + \
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 2.0e2)                * (0.05)}
} 



#################################
# Energy resolution for electrons
#################################

module EnergySmearing ElectronEnergySmearing {
  set InputArray ElectronTrackingEfficiency/electrons
  set OutputArray electrons

  # set ResolutionFormula {resolution formula as a function of eta and energy}
  set ResolutionFormula {                  (abs(eta) <= 2.5) * (energy > 0.1   && energy <= 2.5e1) * (energy*0.015) + \
                                           (abs(eta) <= 2.5) * (energy > 2.5e1)                    * sqrt(energy^2*0.005^2 + energy*0.027^2 + 0.15^2) + \
                         (abs(eta) > 2.5 && abs(eta) <= 3.0)                                       * sqrt(energy^2*0.005^2 + energy*0.027^2 + 0.15^2) + \
                         (abs(eta) > 3.0 && abs(eta) <= 5.0)                                       * sqrt(energy^2*0.08^2 + energy*1.97^2)}
}

module EnergySmearing ElectronEnergySmearingNoPU {
  set InputArray ElectronTrackingEfficiencyNoPU/electrons
  set OutputArray electrons

    # set ResolutionFormula {resolution formula as a function of eta and energy}
  set ResolutionFormula {                  (abs(eta) <= 2.5) * (energy > 0.1   && energy <= 2.5e1) * (energy*0.015) + \
                                           (abs(eta) <= 2.5) * (energy > 2.5e1)                    * sqrt(energy^2*0.005^2 + energy*0.027^2 + 0.15^2) + \
                         (abs(eta) > 2.5 && abs(eta) <= 3.0)                                       * sqrt(energy^2*0.005^2 + energy*0.027^2 + 0.15^2) + \
                         (abs(eta) > 3.0 && abs(eta) <= 5.0)                                       * sqrt(energy^2*0.08^2 + energy*1.97^2)}
}


###############################
# Momentum resolution for muons
###############################

module InverseMomentumSmearing MuonMomentumSmearing {
  set InputArray MuonTrackingEfficiency/muons
  set OutputArray muons

  # set ResolutionFormula {resolution formula as a function of eta and pt}

  # resolution formula for muons
  set ResolutionFormula {(0.0297527+0.00014987*pt-6.30357e-8*pt*pt+2.65056e-11*pt*pt*pt)}
}

module InverseMomentumSmearing MuonMomentumSmearingNoPU {
  set InputArray MuonTrackingEfficiencyNoPU/muons
  set OutputArray muons

  # set ResolutionFormula {resolution formula as a function of eta and pt}

  # resolution formula for muons
  set ResolutionFormula {(0.0297527+0.00014987*pt-6.30357e-8*pt*pt+2.65056e-11*pt*pt*pt)}
}


##############
# Track merger
##############

module Merger TrackMerger {
# add InputArray InputArray
  add InputArray ChargedHadronMomentumSmearing/chargedHadrons
  add InputArray ElectronEnergySmearing/electrons
  set OutputArray tracks
}

module Merger TrackMergerNoPU {
# add InputArray InputArrxcay
  add InputArray ChargedHadronMomentumSmearingNoPU/chargedHadrons
  add InputArray ElectronEnergySmearingNoPU/electrons
  set OutputArray tracks
}



#############
# Calorimeter
#############

module Calorimeter Calorimeter {
    
  set TimingEMin 0.5

  set ParticleInputArray ParticlePropagator/stableParticles
  set TrackInputArray TrackMerger/tracks

  set TowerOutputArray towers
  set PhotonOutputArray photons

  set EFlowTrackOutputArray eflowTracks
  set EFlowTowerOutputArray eflowTowers

  set pi [expr {acos(-1)}]

  # lists of the edges of each tower in eta and phi
  # each list starts with the lower edge of the first tower
  # the list ends with the higher edged of the last tower

  # 5 degrees towers
  set PhiBins {}
  for {set i -36} {$i <= 36} {incr i} {
    add PhiBins [expr {$i * $pi/36.0}]
  }
  foreach eta {-1.566 -1.479 -1.392 -1.305 -1.218 -1.131 -1.044 -0.957 -0.87 -0.783 -0.696 -0.609 -0.522 -0.435 -0.348 -0.261 -0.174 -0.087 0 0.087 0.174 0.261 0.348 0.435 0.522 0.609 0.696 0.783 0.87 0.957 1.044 1.131 1.218 1.305 1.392 1.479 1.566 1.653} {
    add EtaPhiBins $eta $PhiBins
  }

  # 10 degrees towers
  set PhiBins {}
  for {set i -18} {$i <= 18} {incr i} {
    add PhiBins [expr {$i * $pi/18.0}]
  }
  foreach eta {-4.35 -4.175 -4 -3.825 -3.65 -3.475 -3.3 -3.125 -2.95 -2.868 -2.65 -2.5 -2.322 -2.172 -2.043 -1.93 -1.83 -1.74 -1.653 1.74 1.83 1.93 2.043 2.172 2.322 2.5 2.65 2.868 2.95 3.125 3.3 3.475 3.65 3.825 4 4.175 4.35 4.525} {
    add EtaPhiBins $eta $PhiBins
  }

  # 20 degrees towers
  set PhiBins {}
  for {set i -9} {$i <= 9} {incr i} {
    add PhiBins [expr {$i * $pi/9.0}]
  }
  foreach eta {-5 -4.7 -4.525 4.7 5} {
    add EtaPhiBins $eta $PhiBins
  }

  # default energy fractions {abs(PDG code)} {Fecal Fhcal}
  add EnergyFraction {0} {0.0 1.0}
  # energy fractions for e, gamma and pi0
  add EnergyFraction {11} {1.0 0.0}
  add EnergyFraction {22} {1.0 0.0}
  add EnergyFraction {111} {1.0 0.0}
  # energy fractions for muon, neutrinos and neutralinos
  add EnergyFraction {12} {0.0 0.0}
  add EnergyFraction {13} {0.0 0.0}
  add EnergyFraction {14} {0.0 0.0}
  add EnergyFraction {16} {0.0 0.0}
  add EnergyFraction {1000022} {0.0 0.0}
  add EnergyFraction {1000023} {0.0 0.0}
  add EnergyFraction {1000025} {0.0 0.0}
  add EnergyFraction {1000035} {0.0 0.0}
  add EnergyFraction {1000045} {0.0 0.0}
  # energy fractions for K0short and Lambda
  add EnergyFraction {310} {0.3 0.7}
  add EnergyFraction {3122} {0.3 0.7}

  # set ECalResolutionFormula {resolution formula as a function of eta and energy}
  set ECalResolutionFormula {                  (abs(eta) <= 1.497) * sqrt(energy^2*0.007^2 + energy*0.029^2 + 1.01^2) + \
                                               (abs(eta) > 1.497 && abs(eta)<=3.0) * sqrt(energy^2*0.02^2 + energy*0.087^2 + 1.95^2) + \
                             (abs(eta) > 3.0 && abs(eta) <= 5.0) * sqrt(energy^2*0.29^2 + energy*0.86^2 + 191^2)}


  # set HCalResolutionFormula {resolution formula as a function of eta and energy}
    set HCalResolutionFormula {                  (abs(eta) <= 1.7) * (energy*0.132 - sqrt(energy)*0.285 + 10) + \
                 
                                                 (abs(eta) > 1.7 && abs(eta)<=2.1) * (energy*0.0737 - sqrt(energy)*0.0343 + 7.3) + \
                                                 (abs(eta) > 2.1 && abs(eta)<=2.3) * (energy*0.239 + sqrt(energy)*1.95 + 19.1) + \

                                                 (abs(eta) > 2.3 && abs(eta) <= 5.0) * (energy*0.0732 + sqrt(energy)*14.7+42.8)}

}

module Calorimeter CalorimeterNoPU {
  set ParticleInputArray ParticlePropagatorNoPU/stableParticles
  set TrackInputArray TrackMergerNoPU/tracks

  set TowerOutputArray towers
  set PhotonOutputArray photons

  set EFlowTrackOutputArray eflowTracks
  set EFlowTowerOutputArray eflowTowers

  set pi [expr {acos(-1)}]

  # lists of the edges of each tower in eta and phi
  # each list starts with the lower edge of the first tower
  # the list ends with the higher edged of the last tower

  # 5 degrees towers
  set PhiBins {}
  for {set i -36} {$i <= 36} {incr i} {
    add PhiBins [expr {$i * $pi/36.0}]
  }
  foreach eta {-1.566 -1.479 -1.392 -1.305 -1.218 -1.131 -1.044 -0.957 -0.87 -0.783 -0.696 -0.609 -0.522 -0.435 -0.348 -0.261 -0.174 -0.087 0 0.087 0.174 0.261 0.348 0.435 0.522 0.609 0.696 0.783 0.87 0.957 1.044 1.131 1.218 1.305 1.392 1.479 1.566 1.653} {
    add EtaPhiBins $eta $PhiBins
  }

  # 10 degrees towers
  set PhiBins {}
  for {set i -18} {$i <= 18} {incr i} {
    add PhiBins [expr {$i * $pi/18.0}]
  }
  foreach eta {-4.35 -4.175 -4 -3.825 -3.65 -3.475 -3.3 -3.125 -2.95 -2.868 -2.65 -2.5 -2.322 -2.172 -2.043 -1.93 -1.83 -1.74 -1.653 1.74 1.83 1.93 2.043 2.172 2.322 2.5 2.65 2.868 2.95 3.125 3.3 3.475 3.65 3.825 4 4.175 4.35 4.525} {
    add EtaPhiBins $eta $PhiBins
  }

  # 20 degrees towers
  set PhiBins {}
  for {set i -9} {$i <= 9} {incr i} {
    add PhiBins [expr {$i * $pi/9.0}]
  }
  foreach eta {-5 -4.7 -4.525 4.7 5} {
    add EtaPhiBins $eta $PhiBins
  }

  # default energy fractions {abs(PDG code)} {Fecal Fhcal}
  add EnergyFraction {0} {0.0 1.0}
  # energy fractions for e, gamma and pi0
  add EnergyFraction {11} {1.0 0.0}
  add EnergyFraction {22} {1.0 0.0}
  add EnergyFraction {111} {1.0 0.0}
  # energy fractions for muon, neutrinos and neutralinos
  add EnergyFraction {12} {0.0 0.0}
  add EnergyFraction {13} {0.0 0.0}
  add EnergyFraction {14} {0.0 0.0}
  add EnergyFraction {16} {0.0 0.0}
  add EnergyFraction {1000022} {0.0 0.0}
  add EnergyFraction {1000023} {0.0 0.0}
  add EnergyFraction {1000025} {0.0 0.0}
  add EnergyFraction {1000035} {0.0 0.0}
  add EnergyFraction {1000045} {0.0 0.0}
  # energy fractions for K0short and Lambda
  add EnergyFraction {310} {0.3 0.7}
  add EnergyFraction {3122} {0.3 0.7}

  # set ECalResolutionFormula {resolution formula as a function of eta and energy}
  set ECalResolutionFormula {                  (abs(eta) <= 1.497) * sqrt(energy^2*0.007^2 + energy*0.029^2 + 1.01^2) + \
                                               (abs(eta) > 1.497 && abs(eta)<=3.0) * sqrt(energy^2*0.02^2 + energy*0.087^2 + 1.95^2) + \
                             (abs(eta) > 3.0 && abs(eta) <= 5.0) * sqrt(energy^2*0.29^2 + energy*0.86^2 + 191^2)}


  # set HCalResolutionFormula {resolution formula as a function of eta and energy}
    set HCalResolutionFormula {                  (abs(eta) <= 1.7) * (energy*0.132 - sqrt(energy)*0.285 + 10) + \
                             
                                                 (abs(eta) > 1.7 && abs(eta)<=2.1) * (energy*0.0737 - sqrt(energy)*0.0343 + 7.3) + \
                                                 (abs(eta) > 2.1 && abs(eta)<=2.3) * (energy*0.239 + sqrt(energy)*1.95 + 19.1) + \

                                                 (abs(eta) > 2.3 && abs(eta) <= 5.0) * (energy*0.0732 + sqrt(energy)*14.7+42.8)}

}


##########################
# Track pile-up subtractor
##########################

module TrackPileUpSubtractor TrackPileUpSubtractor {
# add InputArray InputArray OutputArray
  add InputArray Calorimeter/eflowTracks eflowTracks
  add InputArray ElectronEnergySmearing/electrons electrons
  add InputArray MuonMomentumSmearing/muons muons

  set PVInputArray  ModifyBeamSpot/PV

  # assume perfect pile-up subtraction for tracks with |z| > fZVertexResolution
  # Z vertex resolution in m
  set ZVertexResolution 0.0001
}

####################
# Energy flow merger
####################

module Merger EFlowMerger {
# add InputArray InputArray
  add InputArray TrackPileUpSubtractor/eflowTracks
  add InputArray Calorimeter/eflowTowers
  add InputArray MuonMomentumSmearing/muons
  set OutputArray eflow
}

module Merger EFlowMergerNoPU {
# add InputArray InputArray
  add InputArray CalorimeterNoPU/eflowTracks
  add InputArray CalorimeterNoPU/eflowTowers
  add InputArray MuonMomentumSmearingNoPU/muons
  set OutputArray eflow
}


#############
# Rho pile-up
#############

module FastJetFinder Rho {
#  set InputArray Calorimeter/towers
  set InputArray EFlowMerger/eflow

  set ComputeRho true
  set RhoOutputArray rho

  # area algorithm: 0 Do not compute area, 1 Active area explicit ghosts, 2 One ghost passive area, 3 Passive area, 4 Voronoi, 5 Active area
  set AreaAlgorithm 5

  # jet algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 4
  set ParameterR 0.4
  set GhostEtaMax 5.0
  set RhoEtaMax 5.0

  add RhoEtaRange 0.0 2.5
  add RhoEtaRange 2.5 4.0
  add RhoEtaRange 4.0 5.0

  set JetPTMin 0.0
}

module FastJetFinder GlobalRho {
#  set InputArray Calorimeter/towers
  set InputArray EFlowMerger/eflow

  set ComputeRho true
  set RhoOutputArray rho

  # area algorithm: 0 Do not compute area, 1 Active area explicit ghosts, 2 One ghost passive area, 3 Passive area, 4 Voronoi, 5 Active area
  set AreaAlgorithm 5
  
  # jet algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 4
  set ParameterR 0.4
  set GhostEtaMax 5.0
  set RhoEtaMax 5.0
  
  add RhoEtaRange 0.0 5.0

  set JetPTMin 0.0
}


#####################
# MC truth jet finder
#####################

module FastJetFinder GenJetFinder {
  set InputArray Delphes/stableParticles

  set OutputArray jets

  # algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 6
  set ParameterR 0.4

  set JetPTMin 5.0

}

module NeutrinoFilter NeutrinoFilter {
  set InputArray Delphes/stableParticles

  set OutputArray stableParticles  
}

module FastJetFinder GenJetFinderNoNu {
  set InputArray NeutrinoFilter/stableParticles
  
  set OutputArray jets

  # algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 6
  set ParameterR 0.4
  
  set JetPTMin 5.0

}


############
# Jet finder
############

module FastJetFinder FastJetFinder {
#  set InputArray Calorimeter/towers
  set InputArray EFlowMerger/eflow

  set OutputArray jets

  # area algorithm: 0 Do not compute area, 1 Active area explicit ghosts, 2 One ghost passive area, 3 Passive area, 4 Voronoi, 5 Active area
  set AreaAlgorithm 5

  # jet algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 6
  set ParameterR 0.4

  set JetPTMin 5.0
}

module FastJetFinder FastJetFinderNoPU {
#  set InputArray CalorimeterNoPU/towers
  set InputArray EFlowMergerNoPU/eflow

  set OutputArray jets

  # area algorithm: 0 Do not compute area, 1 Active area explicit ghosts, 2 One ghost passive area, 3 Passive area, 4 Voronoi, 5 Active area
  set AreaAlgorithm 5

  # jet algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 6
  set ParameterR 0.4

  set JetPTMin 5.0
}



############
# Cambridge-Aachen Jet finder
############

module FastJetFinder CAJetFinder {
#  set InputArray Calorimeter/towers
  set InputArray EFlowMerger/eflow
  set OutputArray jets
  # algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set AreaAlgorithm 5
  set JetAlgorithm 5
  set ParameterR 0.8
  # 200 GeV needed for boosted W bosons, 300 GeV is safe for boosted tops
  set JetPTMin 200.0
}

####################
# Constituent filter
####################

module ConstituentFilter ConstituentFilter {

  set ConEMin 1.

# # add JetInputArray InputArray
   add JetInputArray GenJetFinderNoNu/jets

# SZ changed this but it seems sensible
#   add JetInputArray FastJetFinder/jets
#   add JetInputArray UniqueObjectFinderMJ/jets
  add JetInputArray JetPileUpSubtractor/jets

#   add JetInputArray CAJetFinder/jets


# # add ConstituentInputArray InputArray OutputArray
   add ConstituentInputArray Delphes/stableParticles stableParticles
   add ConstituentInputArray TrackPileUpSubtractor/eflowTracks eflowTracks
   add ConstituentInputArray Calorimeter/eflowTowers eflowTowers
   add ConstituentInputArray MuonMomentumSmearing/muons muons
  # }



###########################
# Jet Pile-Up Subtraction
###########################

module JetPileUpSubtractor JetPileUpSubtractor {
  set JetInputArray FastJetFinder/jets
  set RhoInputArray Rho/rho

  set OutputArray jets

  set JetPTMin 5.0
}

module JetPileUpSubtractor CAJetPileUpSubtractor {
  set JetInputArray CAJetFinder/jets
  set RhoInputArray Rho/rho
  set OutputArray jets
  set JetPTMin 20.0
}


###################
# Photon efficiency
###################

module Efficiency PhotonEfficiency {
  set InputArray Calorimeter/photons
  set OutputArray photons

  # set EfficiencyFormula {efficiency formula as a function of eta and pt}

  # efficiency formula for photons
  set EfficiencyFormula {                                      (pt <= 20.0) * (0.00) + \
                                                               (abs(eta) <= 1.5) * (pt > 20 && pt <= 30) * (0.24) + \
                                                               (abs(eta) <= 1.5) * (pt > 30 && pt <= 40) * (0.51) + \
                                                               (abs(eta) <= 1.5) * (pt > 40 && pt <= 50) * (0.73) + \
						               (abs(eta) <= 1.5) * (pt > 50 && pt <= 60) * (0.86) + \
							       (abs(eta) <= 1.5) * (pt > 60 && pt <= 70) * (0.91) + \
							       (abs(eta) <= 1.5) * (pt > 70 && pt <= 80) * (0.94) + \
							       (abs(eta) <= 1.5) * (pt > 80 && pt <= 90) * (0.96) + \
							       (abs(eta) <= 1.5) * (pt > 90 && pt <= 100) * (0.97) + \
							       (abs(eta) <= 1.5) * (pt > 100 && pt <= 110) * (0.97) + \
							       (abs(eta) <= 1.5) * (pt > 110 && pt <= 120) * (0.98) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 20 && pt <= 30) * (0.14) + \
 							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 30 && pt <= 40) * (0.32) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 40 && pt <= 50) * (0.50) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 50 && pt <= 60) * (0.68) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 60 && pt <= 70) * (0.78) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 70 && pt <= 80) * (0.84) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 80 && pt <= 90) * (0.89) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 90 && pt <= 100) * (0.92) + \
							       (abs(eta) > 1.5 && abs(eta)<=2.5) * (pt > 100 && pt <= 110) * (0.93) + \
                                                               (abs(eta) > 2.5)                                   * (0.00)}
}

##################
# Photon isolation
##################

module Isolation PhotonIsolation {
  set CandidateInputArray PhotonEfficiency/photons
  set IsolationInputArray EFlowMerger/eflow
  set RhoInputArray Rho/rho

  set OutputArray photons

  set DeltaRMax 0.3

  set PTMin 1.0

  set PTRatioMax 9999.
}

#####################
# Electron efficiency
#####################

module Efficiency ElectronEfficiency {
  set InputArray TrackPileUpSubtractor/electrons
  set OutputArray electrons

  # set EfficiencyFormula {efficiency formula as a function of eta and pt}

  # efficiency formula for electrons
    set EfficiencyFormula {                                      (pt <= 4.0)  * (0.00) + \
                         (abs(eta) <= 1.45 ) * (pt >  4.0 && pt <= 6.0)   * (0.5*0.50) + \
                         (abs(eta) <= 1.45 ) * (pt >  6.0 && pt <= 8.0)   * (0.5*0.70) + \
                         (abs(eta) <= 1.45 ) * (pt >  8.0 && pt <= 10.0)  * (0.7*0.85) + \
                         (abs(eta) <= 1.45 ) * (pt > 10.0 && pt <= 30.0)  * (0.90*0.94) + \                                                      
                         (abs(eta) <= 1.45 ) * (pt > 30.0 && pt <= 50.0)  * (0.95*0.97) + \                          
                         (abs(eta) <= 1.45 ) * (pt > 50.0 && pt <= 70.0)  * (0.95*0.98) + \          
                         (abs(eta) <= 1.45 ) * (pt > 70.0 )  * (1.0) + \                                                                                                                               
                         (abs(eta) > 1.45  && abs(eta) <= 1.55) * (pt >  4.0 && pt <= 10.0)   * (0.5*0.35) + \
                         (abs(eta) > 1.45  && abs(eta) <= 1.55) * (pt > 10.0 && pt <= 30.0)   * (0.5*0.40) + \   
                         (abs(eta) > 1.45  && abs(eta) <= 1.55) * (pt > 30.0 && pt <= 70.0)   * (0.8*0.45) + \                                 
                         (abs(eta) > 1.45  && abs(eta) <= 1.55) * (pt > 70.0 )  * (0.8*0.45) + \    
                         (abs(eta) >= 1.55 && abs(eta) <= 2.0 ) * (pt >  4.0 && pt <= 10.0)  * (0.7*0.75) + \
                         (abs(eta) >= 1.55 && abs(eta) <= 2.0 ) * (pt > 10.0 && pt <= 30.0)  * (0.80*0.85) + \                                                      
                         (abs(eta) >= 1.55 && abs(eta) <= 2.0 ) * (pt > 30.0 && pt <= 50.0)  * (0.85*0.95) + \                          
                         (abs(eta) >= 1.55 && abs(eta) <= 2.0 ) * (pt > 50.0 && pt <= 70.0)  * (0.85*0.95) + \          
                         (abs(eta) >= 1.55 && abs(eta) <= 2.0 ) * (pt > 70.0 )  * (0.85*1.0) + \   
                         (abs(eta) >= 2.0 && abs(eta) <= 2.5 ) * (pt >  4.0 && pt <= 10.0)  * (0.7*0.65) + \
                         (abs(eta) >= 2.0 && abs(eta) <= 2.5 ) * (pt > 10.0 && pt <= 30.0)  * (0.7*0.75) + \                                                      
                         (abs(eta) >= 2.0 && abs(eta) <= 2.5 ) * (pt > 30.0 && pt <= 50.0)  * (0.8*0.85) + \                          
                         (abs(eta) >= 2.0 && abs(eta) <= 2.5 ) * (pt > 50.0 && pt <= 70.0)  * (0.8*0.85) + \          
                         (abs(eta) >= 2.0 && abs(eta) <= 2.5 ) * (pt > 70.0 )  * (0.8*0.85) + \                                                                                                              
	(abs(eta) > 2.5)                              * (0.00)}

}

####################
# Electron isolation
####################

module Isolation ElectronIsolation {
  set CandidateInputArray ElectronEfficiency/electrons
  set IsolationInputArray EFlowMerger/eflow
  set RhoInputArray Rho/rho

  set OutputArray electrons

  set DeltaRMax 0.3

  set PTMin 1.0

  set PTRatioMax 9999.
}

#################
# Muon efficiency
#################

module Efficiency MuonEfficiency {
  set InputArray TrackPileUpSubtractor/muons
  set OutputArray muons

  # set EfficiencyFormula {efficiency as a function of eta and pt}

  # efficiency formula for muons
    set EfficiencyFormula {                                    (pt <= 10.0)  * (0.00) + \  
                         (abs(eta)<=0.1)*(pt>10)*(0.89865) + \
                         (abs(eta)>0.1 && abs(eta)<=0.2)*(pt>10)*(0.894596) + \
                         (abs(eta)>0.2 && abs(eta)<=0.3)*(pt>10)*(0.764087) + \
                         (abs(eta)>0.3 && abs(eta)<=0.4)*(pt>10)*(0.881295) + \
                         (abs(eta)>0.4 && abs(eta)<=0.5)*(pt>10)*(0.913192) + \
                         (abs(eta)>0.5 && abs(eta)<=0.6)*(pt>10)*(0.897579) + \
                         (abs(eta)>0.6 && abs(eta)<=0.7)*(pt>10)*(0.894978) + \
                         (abs(eta)>0.7 && abs(eta)<=0.8)*(pt>10)*(0.878466) + \
                         (abs(eta)>0.8 && abs(eta)<=0.9)*(pt>10)*(0.831849) + \
                         (abs(eta)>0.9 && abs(eta)<=1.0)*(pt>10)*(0.806424) + \
                         (abs(eta)>1.0 && abs(eta)<=1.1)*(pt>10)*(0.756892) + \      
                         (abs(eta)>1.1 && abs(eta)<=1.2)*(pt>10)*(0.728583) + \
                         (abs(eta)>1.2 && abs(eta)<=1.3)*(pt>10)*(0.773855) + \
                         (abs(eta)>1.3 && abs(eta)<=1.4)*(pt>10)*(0.776296) + \
                         (abs(eta)>1.4 && abs(eta)<=1.5)*(pt>10)*(0.769977) + \
                         (abs(eta)>1.5 && abs(eta)<=1.6)*(pt>10)*(0.838174) + \
                         (abs(eta)>1.6 && abs(eta)<=1.7)*(pt>10)*(0.854358) + \
                         (abs(eta)>1.7 && abs(eta)<=1.8)*(pt>10)*(0.8565) + \
                         (abs(eta)>1.8 && abs(eta)<=1.9)*(pt>10)*(0.857182) + \
                         (abs(eta)>1.9 && abs(eta)<=2.0)*(pt>10)*(0.85591) + \
                         (abs(eta)>2.0 && abs(eta)<=2.1)*(pt>10)*(0.844826) + \
                         (abs(eta)>2.1 && abs(eta)<=2.2)*(pt>10)*(0.81742) + \
                         (abs(eta)>2.2 && abs(eta)<=2.3)*(pt>10)*(0.825831) + \
                         (abs(eta)>2.3 && abs(eta)<=2.4)*(pt>10)*(0.774208) + \
                         (abs(eta) > 2.40)  * (0.00)}
}

################
# Muon isolation
################

module Isolation MuonIsolation {
  set CandidateInputArray MuonEfficiency/muons
  set IsolationInputArray EFlowMerger/eflow
  set RhoInputArray Rho/rho

  set OutputArray muons

  set DeltaRMax 0.3

  set PTMin 1.0

  set PTRatioMax 9999.
}

###################
# Missing ET merger
###################

module Merger MissingET {
# add InputArray InputArray
  add InputArray EFlowMerger/eflow
  set MomentumOutputArray momentum
}

module Merger GenMissingET {
#  add InputArray Delphes/stableParticles
  add InputArray NeutrinoFilter/stableParticles
  set MomentumOutputArray momentum
}

module Merger PuppiMissingET {
  add InputArray RunPUPPI/weightedparticles
  set MomentumOutputArray momentum
}

##################
# Scalar HT merger
##################
module Merger ScalarHT {
# add InputArray InputArray
  add InputArray UniqueObjectFinderMJ/jets
  add InputArray UniqueObjectFinderEJ/electrons
  add InputArray UniqueObjectFinderGJ/photons
  add InputArray UniqueObjectFinderMJ/muons
#  add InputArray JetPileUpSubtractor/jets
#  add InputArray ElectronIsolation/electrons
#  add InputArray PhotonIsolation/photons
#  add InputArray MuonIsolation/muons
  set EnergyOutputArray energy
}

###########
# b-tagging
###########

module BTagging BTaggingLoose  {

# float effi_X_phase1old_X_loose

  set PartonInputArray Delphes/partons
  set JetInputArray FastJetFinder/jets

  set BitNumber 1
  set DeltaR 0.5
  set PartonPTMin 1.0
  set PartonEtaMax 2.5

  # add EfficiencyFormula {abs(PDG code)} {efficiency formula as a function of eta and pt}
  # PDG code = the highest PDG code of a quark or gluon inside DeltaR cone around jet axis
  # gluon's PDG code has the lowest priority
  # default efficiency formula (misidentification rate)
   add EfficiencyFormula {0} {                                  (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.0965) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.105) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.0762) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.0851) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.0739) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.0808) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.0863) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.0824) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.0891) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.0977) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.1028) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.105) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.1116) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.1225) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.1384) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.1535) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.1693) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.1869) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.2111) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.2063) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.2132) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.216) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.2273) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.2686) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.3134) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.054932) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.078226) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.059492) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.07064) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.071246) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.081144) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.088663) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.080107) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.087845) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.099813) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.103151) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.101119) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.109951) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.120709) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.1346) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.1524) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.165067) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.108622) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.124293) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.0823) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.086487) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.09222) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.000) + \
                                                (abs(eta) > 2.4) * (0.000)}
 

  # efficiency formula for c-jets (misidentification rate)
  add EfficiencyFormula {4} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.307) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.355) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.315) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.332) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.313) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.322) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.331) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.312) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.319) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.329) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.317) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.301) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.306) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.309) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.309) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.309) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.313) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.308) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.321) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.287) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.295) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.278) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.293) + \                                    
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.351) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.388) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.15416) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.20465) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.17009) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.18172) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.19284) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.19356) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.20196) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.18933) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.19708) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.20503) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.20163) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.18223) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.18792) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.19688) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.21584) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.22609) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.24573) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.15426) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.17006) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.14041) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.10447) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.15677) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.) + \
                                                (abs(eta) > 2.4) * (0.000)}

  # efficiency formula for b-jets
  add EfficiencyFormula {5} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.634) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.723) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.721) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.747) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.745) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.755) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.762) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.762) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.753) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.75) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.738) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.723) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.714) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.691) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.669) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.646) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.625) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.614) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.585) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.519) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.494) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.453) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.438) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.486) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.541) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.4585) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.5768) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.577) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.6064) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.6202) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.6085) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.6178) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.5966) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.587) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.5785) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.5605) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.5103) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.5111) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.4889) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.4697) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.4361) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.4178) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.3698) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.3255) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.2703) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.2767) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.2941) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.0) + \
                                                (abs(eta) > 2.4) * (0.000)}
}

module BTagging BTaggingMedium {

# float effi_X_phase1old_X_medium

  set PartonInputArray Delphes/partons
  set JetInputArray FastJetFinder/jets

  set BitNumber 1
  set DeltaR 0.5
  set PartonPTMin 1.0
  set PartonEtaMax 2.5

  # add EfficiencyFormula {abs(PDG code)} {efficiency formula as a function of eta and pt}
  # PDG code = the highest PDG code of a quark or gluon inside DeltaR cone around jet axis
  # gluon's PDG code has the lowest priority
  # default efficiency formula (misidentification rate)
   add EfficiencyFormula {0} {                                  (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.00469) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.00691) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.00519) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.00633) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.00574) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.00656) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.0073) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.00606) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.00722) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.00837) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.01031) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.01224) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.01351) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.01542) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.01796) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.02099) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.0246) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.01638) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.01989) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.01629) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.01773) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.01977) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.02372) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.0323) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.04635) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.04635) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.004389) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.004706) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.00583) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.004895) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.006023) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.006487) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.005549) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.006939) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.008245) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.009879) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.011744) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.012714) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.014575) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.01848) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.022346) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.024952) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.007563) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.010131) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.004863) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.006965) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.007071) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.000) + \
                                                (abs(eta) > 2.4) * (0.000)}


  # efficiency formula for c-jets (misidentification rate)
  add EfficiencyFormula {4} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.0534) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.0677) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.0559) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.0616) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.0603) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.0641) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.0647) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.064) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.066) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.0666) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.0679) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.0701) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.0664) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.0688) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.0671) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.0654) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.0651) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.0452) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.0484) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.0346) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.0357) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.035) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.0425) + \                                    
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.0635) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.0951) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.0124) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.01787) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.01962) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.01831) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.01842) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.0224) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.0198) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.02005) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.02146) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.02519) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.02979) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.03011) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.03065) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.0338) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.03664) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.04036) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.04268) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.0142) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.00971) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.00759) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.00746) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.00423) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.0) + \
                                                (abs(eta) > 2.4) * (0.000)}

  # efficiency formula for b-jets
  add EfficiencyFormula {5} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.3392) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.4447) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.4628) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.489) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.5029) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.5074) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.5154) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.5077) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.5028) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.4922) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.4739) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.4623) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.4415) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.4134) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.3822) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.351) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.3212) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.2507) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.2098) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.154) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.1472) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.136) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.142) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.1915) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.2249) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.1792) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.2611) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.2846) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.2907) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.2949) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.2875) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.2812) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.2927) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.2668) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.2832) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.2488) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.2297) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.2106) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.1991) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.1764) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.1779) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.1569) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.0812) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.0634) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.0444) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.0625) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.0661) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.0) + \
                                                (abs(eta) > 2.4) * (0.000)}

}

module BTagging BTaggingTight  {

# float effi_X_phase1old_X_tight

  set PartonInputArray Delphes/partons
  set JetInputArray FastJetFinder/jets

  set BitNumber 1
  set DeltaR 0.5
  set PartonPTMin 1.0
  set PartonEtaMax 2.5

  # add EfficiencyFormula {abs(PDG code)} {efficiency formula as a function of eta and pt}
  # PDG code = the highest PDG code of a quark or gluon inside DeltaR cone around jet axis
  # gluon's PDG code has the lowest priority
  # default efficiency formula (misidentification rate)
   add EfficiencyFormula {0} {                                  (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.0002) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.00027) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.000278) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.000343) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.000343) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.00045) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.000469) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.000449) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.000556) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.000731) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.000929) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.001311) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.00152) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.001657) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.002124) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.00254) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.00292) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.00116) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.001368) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.001201) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.001249) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.001548) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.001898) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.003125) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.004864) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.000476) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.000538) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.000468) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.000687) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.000624) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.00072) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.0008) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.000572) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.000843) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.00101) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.000999) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.000763) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.001088) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.001204) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.001871) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.00216) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.003148) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.003421) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.004692) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.005582) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.005732) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.007186) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.000) + \
                                                (abs(eta) > 2.4) * (0.000)}


  # efficiency formula for c-jets (misidentification rate)
  add EfficiencyFormula {4} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.00329) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.00403) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.00373) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.00437) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.00525) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.0049) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.00506) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.00559) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.00605) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.0069) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.00725) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.00805) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.00741) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.00763) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.00872) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.00731) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.00773) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.00383) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.00377) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.00239) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.00264) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.00266) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.00362)+ \                                    
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.00498) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.01455) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.00387) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.00553) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.00654) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.00657) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.00629) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.00595) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.00533) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.00361) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.00416) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.00658) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.0044) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.0036) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.00154) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.0028) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.00296) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.00352) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.00731) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.0044) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.01068) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.01138) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.00746) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.00847) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.0) + \
                                                (abs(eta) > 2.4) * (0.000)}

  # efficiency formula for b-jets
  add EfficiencyFormula {5} {                                      (pt <= 20.0) * (0.000) + \
                                                (abs(eta) <= 1.8) * (pt > 20.0 && pt <= 30) * (0.1371) + \
                                                (abs(eta) <= 1.8) * (pt > 30.0 && pt <= 40) * (0.1973) + \
                                                (abs(eta) <= 1.8) * (pt > 40.0 && pt <= 50) * (0.2189) + \
                                                (abs(eta) <= 1.8) * (pt > 50.0 && pt <= 60) * (0.231) + \
                                                (abs(eta) <= 1.8) * (pt > 60.0 && pt <= 70) * (0.2494) + \
                                                (abs(eta) <= 1.8) * (pt > 70.0 && pt <= 80) * (0.2514) + \
                                                (abs(eta) <= 1.8) * (pt > 80.0 && pt <= 90) * (0.2529) + \
                                                (abs(eta) <= 1.8) * (pt > 90.0 && pt <= 100) * (0.2482) + \
                                                (abs(eta) <= 1.8) * (pt > 100.0 && pt <= 120) * (0.2464) + \
                                                (abs(eta) <= 1.8) * (pt > 120.0 && pt <= 140) * (0.2328) + \
                                                (abs(eta) <= 1.8) * (pt > 140.0 && pt <= 160) * (0.212) + \
                                                (abs(eta) <= 1.8) * (pt > 160.0 && pt <= 180) * (0.1854) + \
                                                (abs(eta) <= 1.8) * (pt > 180.0 && pt <= 200) * (0.1706) + \
                                                (abs(eta) <= 1.8) * (pt > 200.0 && pt <= 250) * (0.1559) + \
                                                (abs(eta) <= 1.8) * (pt > 250.0 && pt <= 300) * (0.1361) + \
                                                (abs(eta) <= 1.8) * (pt > 300.0 && pt <= 350) * (0.1203) + \
                                                (abs(eta) <= 1.8) * (pt > 350.0 && pt <= 400) * (0.1065) + \
                                                (abs(eta) <= 1.8) * (pt > 400.0 && pt <= 500) * (0.0534) + \
                                                (abs(eta) <= 1.8) * (pt > 500.0 && pt <= 600) * (0.0396) + \
                                                (abs(eta) <= 1.8) * (pt > 600.0 && pt <= 700) * (0.0277) + \
                                                (abs(eta) <= 1.8) * (pt > 700.0 && pt <= 800) * (0.0303) + \
                                                (abs(eta) <= 1.8) * (pt > 800.0 && pt <= 1000) * (0.0288) + \
                                                (abs(eta) <= 1.8) * (pt > 1000.0 && pt <= 1400) * (0.0335) + \
                                                (abs(eta) <= 1.8) * (pt > 1400.0 && pt <= 2000) * (0.0445) + \
                                                (abs(eta) <= 1.8) * (pt > 2000.0) * (0.0645) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt <= 20.0) * (0.000) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 20.0 && pt <= 30) * (0.0804) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 30.0 && pt <= 40) * (0.1354) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 40.0 && pt <= 50) * (0.1715) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 50.0 && pt <= 60) * (0.182) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 60.0 && pt <= 70) * (0.1832) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 70.0 && pt <= 80) * (0.1818) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 80.0 && pt <= 90) * (0.1648) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 90.0 && pt <= 100) * (0.1621) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 100.0 && pt <= 120) * (0.1414) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 120.0 && pt <= 140) * (0.1446) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 140.0 && pt <= 160) * (0.1069) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 160.0 && pt <= 180) * (0.079) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 180.0 && pt <= 200) * (0.0736) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 200.0 && pt <= 250) * (0.0626) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 250.0 && pt <= 300) * (0.0484) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 300.0 && pt <= 350) * (0.0459) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 350.0 && pt <= 400) * (0.0384) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 400.0 && pt <= 500) * (0.0319) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 500.0 && pt <= 600) * (0.0401) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 600.0 && pt <= 700) * (0.037) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 700.0 && pt <= 800) * (0.0446) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 800.0 && pt <= 1000) * (0.0661) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1000.0 && pt <= 1400) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 1400.0 && pt <= 2000) * (0.0) + \
                                                (abs(eta) > 1.8 && abs(eta) <= 2.4) * (pt > 2000.0) * (0.0) + \
                                                (abs(eta) > 2.4) * (0.000)}
}

##########################
# Track pile-up subtractor
##########################

module TrackPileUpSubtractor TrackPVSubtractor {
# add InputArray InputArray OutputArray
  add InputArray ChargedHadronMomentumSmearing/chargedHadrons chargedHadrons
  add InputArray ElectronEnergySmearing/electrons electrons
  add InputArray MuonMomentumSmearing/muons muons

  set PVInputArray  ModifyBeamSpot/PV

  # assume perfect pile-up subtraction for tracks with |z| > fZVertexResolution
  # Z vertex resolution in m
  set ZVertexResolution 0.0005
}


################
# Isolated Tracks
################
module IsoTrackFilter IsoTrackFilter {
  ## Isolation using all the tracks
  set ElectronInputArray TrackPVSubtractor/electrons
  set MuonInputArray TrackPVSubtractor/muons
  set HADInputArray TrackPVSubtractor/chargedHadrons

  set OutputArray IsoTrack

  ### Cone 0.3
  set DeltaRMax 0.3

  ## PTmin of isolation 
  set PTMin 1

  set PTRatioMax 0.2

  set IsoTrackPTMin 5
}

module TauTagging TauTagging {
  set ParticleInputArray Delphes/allParticles
  set PartonInputArray Delphes/partons
#  set JetInputArray FastJetFinder/jets
  set JetInputArray JetPileUpSubtractor/jets

  set DeltaR 0.4

  set TauPTMin 1.0

  set TauEtaMax 2.5

  # add EfficiencyFormula {abs(PDG code)} {efficiency formula as a function of eta and pt}

  # default efficiency formula (misidentification rate)
  add EfficiencyFormula {0} {(pt > 0.0 && abs(eta)<2.1) * ( pt <= 14.0) * (0.0000) + \
                             (pt > 14.0 && abs(eta)<2.1) * (  pt <= 28.0) * (0.0044) + \
                             (pt > 28.0 && abs(eta)<2.1) * (  pt <= 42.0) * (0.0116) + \
                             (pt > 42.0 && abs(eta)<2.1) * (  pt <= 56.0) * (0.0139) + \
                             (pt > 56.0 && abs(eta)<2.1) * (  pt <= 70.0) * (0.0136) + \
                             (pt > 70.0 && abs(eta)<2.1) * (  pt <= 84.0) * (0.0122) + \
                             (pt > 84.0 && abs(eta)<2.1) * (  pt <= 98.0) * (0.0111) + \
                             (pt > 98.0 && abs(eta)<2.1) * (  pt <= 112.0) * (0.0098) + \
                             (pt > 112.0 && abs(eta)<2.1) * (  pt <= 126.0) * (0.0086) + \
                             (pt > 126.0 && abs(eta)<2.1) * (  pt <= 140.0) * (0.0079) + \
                             (pt > 140.0&& abs(eta)<2.1 ) * (0.0071) + \
                             (abs(eta)>2.1)*(0.0)}
  # efficiency formula for tau-jets
  add EfficiencyFormula {15} {(pt > 0.0 && abs(eta)<2.1) * ( pt <= 14.0) * (0.00) + \
                              (pt > 14.0 && abs(eta)<2.1) * (  pt <= 28.0) * (0.26) + \
                              (pt > 28.0 && abs(eta)<2.1) * (  pt <= 42.0) * (0.41) + \
                              (pt > 42.0 && abs(eta)<2.1) * (  pt <= 56.0) * (0.45) + \
                              (pt > 56.0 && abs(eta)<2.1) * (  pt <= 70.0) * (0.48) + \
                              (pt > 70.0 && abs(eta)<2.1) * (  pt <= 84.0) * (0.49) + \
                              (pt > 84.0 && abs(eta)<2.1) * (  pt <= 98.0) * (0.50) + \
                              (pt > 98.0 && abs(eta)<2.1) * (  pt <= 112.0) * (0.46) + \
                              (pt > 112.0 && abs(eta)<2.1) * (  pt <= 126.0) * (0.46) + \
                              (pt > 126.0 && abs(eta)<2.1) * (  pt <= 140.0) * (0.46) + \
                              (pt > 140.0 && abs(eta)<2.1) * (0.45) +\
			      (abs(eta)>2.1)*(0.0)}
}

#####################################################
# Find uniquely identified photons/electrons/tau/jets
#####################################################

#module UniqueObjectFinder UniqueObjectFinder {
# earlier arrays take precedence over later ones
# add InputArray InputArray OutputArray
#  add InputArray PhotonIsolation/photons photons
#  add InputArray ElectronIsolation/electrons electrons
#  add InputArray JetPileUpSubtractor/jets jets
#}

module UniqueObjectFinder UniqueObjectFinderGJ {
   add InputArray PhotonIsolation/photons photons
   add InputArray JetPileUpSubtractor/jets jets
}

module UniqueObjectFinder UniqueObjectFinderEJ {
   add InputArray ElectronIsolation/electrons electrons
   add InputArray UniqueObjectFinderGJ/jets jets
}

module UniqueObjectFinder UniqueObjectFinderMJ {
   add InputArray MuonIsolation/muons muons
   add InputArray UniqueObjectFinderEJ/jets jets
}

### 
#Pileup jet id
###

module PileUpJetID PileUpJetID {
  set JetInputArray JetPileUpSubtractor/jets
  set OutputArray jets
  set NeutralsInPassingJets eflowTowers

  # Using constituents does not make sense with Charged hadron subtraction                                                                                                           
  # In 0 mode, dR cut used instead                                                                                                                                                   
  set UseConstituents 0

  set TrackInputArray Calorimeter/eflowTracks
  set NeutralInputArray Calorimeter/eflowTowers
  set ParameterR 0.4

  set JetPTMin 5.0

#  set MeanSqDeltaRMaxBarrel 0.13
#  set BetaMinBarrel 0.16
#  set MeanSqDeltaRMaxEndcap 0.07
#  set BetaMinEndcap 0.06
    set MeanSqDeltaRMaxBarrel 0.07
    set BetaMinBarrel 0.13
    set MeanSqDeltaRMaxEndcap 0.07
    set BetaMinEndcap 0.15
  set MeanSqDeltaRMaxForward 0.01

}



##################
# ROOT tree writer
##################

module TreeWriter TreeWriter {
  add Branch StatusPid/filteredParticles Particle GenParticle
  add Branch GenBeamSpotFilter/beamSpotParticles BeamSpotParticle GenParticle

  add Branch FastJetFinder/jets RawJet Jet
  add Branch FastJetFinderNoPU/jets RawJetNoPU Jet

  add Branch GenJetFinder/jets GenJetWithNu Jet
  add Branch GenJetFinderNoNu/jets GenJet Jet
#  add Branch UniqueObjectFinderMJ/jets Jet Jet
#  add Branch UniqueObjectFinderEJ/electrons Electron Electron
#  add Branch UniqueObjectFinderGJ/photons Photon Photon
#  add Branch UniqueObjectFinderMJ/muons Muon Muon
  add Branch JetPileUpSubtractor/jets Jet Jet
  add Branch ElectronIsolation/electrons Electron Electron
  add Branch PhotonIsolation/photons Photon Photon
  add Branch MuonIsolation/muons Muon Muon

  add Branch PileUpJetIDMissingET/momentum PileUpJetIDMissingET MissingET
  add Branch GenMissingET/momentum GenMissingET MissingET
  add Branch PuppiMissingET/momentum PuppiMissingET MissingET


  add Branch MissingET/momentum MissingET MissingET
  add Branch ScalarHT/energy ScalarHT ScalarHT
  add Branch Rho/rho Rho Rho
  add Branch GlobalRho/rho GlobalRho Rho
  add Branch PileUpMerger/NPU NPU ScalarHT
  add Branch IsoTrackFilter/IsoTrack IsoTrack IsoTrack

  add Branch PuppiJetFinder/jets PuppiJet Jet

  set OffsetFromModifyBeamSpot 0

#  add Branch RunPUPPI/weightedparticles PuppiWeightedParticles GenParticle
#  add Branch Delphes/allParticles Particle GenParticle
#  add Branch Calorimeter/eflowTracks EFlowTrack Track
#  add Branch Calorimeter/eflowTowers EFlowTower Tower
#  add Branch MuonMomentumSmearing/muons EFlowMuon Muon
#  add Branch PuppiJetPileUpSubtractor/jets SubtractedPuppiJet Jet
#  add Branch PuppiRho/rho PuppiRho Rho
}

# # add Branch InputArray BranchName BranchClass
#  # add Branch Delphes/allParticles Particle GenParticle
  # add Branch StatusPid/filteredParticles Particle GenParticle
#  # add Branch TrackMerger/tracks Track Track
#  # add Branch Calorimeter/towers Tower Tower
#  # add Branch ConstituentFilter/eflowTracks EFlowTrack Track
#  # add Branch ConstituentFilter/eflowTowers EFlowTower Tower
#  # add Branch ConstituentFilter/muons EFlowMuon Muon
  # add Branch GenJetFinder/jets GenJet Jet
  # add Branch CAJetPileUpSubtractor/jets CAJet Jet
  # add Branch UniqueObjectFinderMJ/jets Jet Jet
  # add Branch UniqueObjectFinderEJ/electrons Electron Electron
  # add Branch UniqueObjectFinderGJ/photons Photon Photon
  # add Branch UniqueObjectFinderMJ/muons Muon Muon
  # add Branch MissingET/momentum MissingET MissingET
  # add Branch ScalarHT/energy ScalarHT ScalarHT
  # add Branch Rho/rho Rho ScalarHT



