```
You are screening a candidate study for inclusion in a systematic review of direct direct drivers of biodiversity loss (sometimes referred to as threats to biodiversity). Based ONLY on the title and abstract, decide whether the study should advance to full-text review.

Title: {title}
Abstract: {abstract}

Answer "retain" if the abstract plausibly indicates:
(a) a comparison of the impacts of at least two types of drivers
(b) on at least one of the indicators or one of the EBV classes, and;
(c) the comparison concerns observed/historical impacts, not only future projections.

Otherwise, answer "exclude"

If you are missing information to make a decision, answer "uncertain", and specify what information you are missing in the "reason" field.

Types of drivers include: Land/sea use change, Direct exploitation of natural resources, Pollution, Invasive alien species, Climate change. Retain studies ONLY if the the drivers fall into one of these categories. Each catgeory is explained below.

## Land/sea use change

- Residential, Commercial & Recreation Areas
- Agriculture & Aquaculture
- Energy Production & Mining
- Transportation, Service & Security Corridors

## Direct exploitation of natural resources

- Hunting, Collecting & Controlling Terrestrial Animals
- Gathering, Harvesting & Controlling Terrestrial Plants & Fungi
- Logging, Harvesting & Controlling Trees
- Fishing, Harvesting & Controlling Aquatic Species
- Recreational Activities
- Conflict, Civil Unrest & Security Activities
- Fire & Fire Management
- Dams & Water Management / Use

## Pollution

- Water-Borne & Other Effluent Pollution
- Garbage & Solid Waste
- Air-Borne Pollutants
- Energy Emissions

## Invasive alien species

- Invasive Non-Native / Alien Species
- Problematic Native Species
- Introduced Genetic Material
- Pathogens


## Climate change

- Changes in Physical & Chemical Regimes
- Changes in Temperature Regimes
- Changes in Precipitation & Hydrological Regimes

## Other

- There could be other things directly driving changes in biodiversity, in which case, simply assign them to the "other" category


Possible EBV classes include (ONLY retain studies if the response variable falls into one of these EBV classes):

+-----------------------------------------+-----------------------------------+
| EBV class                               | EBV name                          |
+-----------------------------------------+-----------------------------------+
| Genetic composition                     | Genetic diversity (richness and   |
|                                         | heterozygosity)                   |
|                                         +-----------------------------------+
|                                         | Genetic differentiation (number   |
|                                         | of genetic units and genetic      |
|                                         | distance)                         |
|                                         +-----------------------------------+
|                                         | Effective population size         |
|                                         +-----------------------------------+
|                                         | Inbreeding                        |
+-----------------------------------------+-----------------------------------+
| Species populations                     | Species distributions             |
|                                         +-----------------------------------+
|                                         | Species abundances                |
+-----------------------------------------+-----------------------------------+
| Species traits                          | Morphology                        |
|                                         +-----------------------------------+
|                                         | Physiology                        |
|                                         +-----------------------------------+
|                                         | Phenology                         |
|                                         +-----------------------------------+
|                                         | Movement                          |
|                                         +-----------------------------------+
|                                         | Reproduction                      |
+-----------------------------------------+-----------------------------------+
| Community composition                   | Community abundance               |
|                                         +-----------------------------------+
|                                         | Taxonomic/phylogenetic diversity  |
|                                         +-----------------------------------+
|                                         | Trait diversity                   |
|                                         +-----------------------------------+
|                                         | Interaction diversity             |
+-----------------------------------------+-----------------------------------+
| Ecosystem functioning                   | Primary productivity              |
|                                         +-----------------------------------+
|                                         | Ecosystem phenology               |
|                                         +-----------------------------------+
|                                         | Ecosystem disturbances            |
+-----------------------------------------+-----------------------------------+
| Ecosystem structure                     | Live cover fraction               |
|                                         +-----------------------------------+
|                                         | Ecosystem distribution            |
|                                         +-----------------------------------+
|                                         | Ecosystem Vertical Profile        |
+-----------------------------------------+-----------------------------------+


## **Genetic populations**

The spatial and temporal variability in the distribution and abundance
of species populations.

 

  --------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------
  EBV name                          EBV description
  Intraspecific genetic diversity   The variation in DNA sequences among individuals of the same species.
  Genetic differentiation           Divergence in genetic composition (identity and frequencies of alleles) among multiple populations.
  Effective population size         The number of individuals in an idealized population that will exhibit the same amount of genetic diversity loss as the population under consideration.
  Inbreeding                        Mating between related individuals.
  --------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------

 

## **Species populations**

The spatial and temporal variability in the distribution and abundance
of species populations.

 

  ----------------------- --------------------------------------------------------------------------------------------------------------------------------
  EBV name                EBV description
  Species distributions   The species occurrence probability over contiguous spatial and temporal units addressing the global extent of a species group.
  Species abundances      Predicted count of individuals over contiguous spatial and temporal units addressing the global extent of a species group.
  ----------------------- --------------------------------------------------------------------------------------------------------------------------------


## **Species traits**

Within-species variation in trait measurements along the axis of
taxonomic diversity.

 

  -------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
  EBV name       EBV description
  Morphology     The variation in physical attributes of organisms of the same species.
  Physiology     Chemical or physical functions promoting organism fitness and responses to environment.
  Phenology      Presence, absence, abundance or duration of seasonal activities of organisms.
  Movement       Behaviors related to the spatial mobility of organisms such as dispersal and migration routes.
  Reproduction   Sexual or asexual production of new individual organisms ('offspring') from parents. Examples: Age at maturity, number of offspring, lifetime reproductive output.
  -------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------


## **Community composition**

The abundance and diversity of organisms making up ecosystems.

 

  ---------------------------------- -------------------------------------------------------------------------------------------------------------
  EBV name                           EBV description
  Community abundance                The abundance of organisms in ecological assemblages.
  Taxonomic/phylogenetic diversity   The diversity of species identities, and/or phylogenetic positions, of organisms in ecological assemblages.
  Trait diversity                    The diversity of functional traits of organisms in ecological assemblages.
  Interaction diversity              The diversity and structure of multi-trophic interactions between organisms in ecological assemblages.
  ---------------------------------- -------------------------------------------------------------------------------------------------------------


## **Ecosystem functioning**

Attributes related to the performance of ecosystems that result from the
collective activities of its organisms.

 

  ------------------------ ----------------------------------------------------------------------------------------------------------------------------------------
  EBV name                 EBV description
  Primary productivity     The rate at which energy is transformed into organic matter primarily through photosynthesis.
  Ecosystem phenology      Duration and magnitude of cyclic processes observed at the ecosystem level, such as in vegetation activity, phytoplankton blooms, etc.
  Ecosystem disturbances   Abrupt deviances in the functioning of the ecosystem from its regular dynamics.
  ------------------------ ----------------------------------------------------------------------------------------------------------------------------------------

## **Ecosystem structure**

The spatial arrangement of ecosystem units collectively defined by
organisms forming these units.


  ---------------------------- --------------------------------------------------------------------------------------------------------------------------------
  EBV name                     EBV description
  Live cover fraction          The horizontal (or projected) fraction of area covered by living organisms, such as vegetation, macroalgae or live hard coral.
  Ecosystem distribution       The horizontal distribution of discrete ecosystem units.
  Ecosystem Vertical Profile   The vertical distribution of biomass in ecosystems, above and below the land surface.
  ---------------------------- --------------------------------------------------------------------------------------------------------------------------------


Indicators: 
- Global bird species richness
- Local species richness
- Local species turnover
- Mean species abundance
- Net primary productivity
- Area of mangrove forest cover
- Extent of intact forest landscapes
- Extent of remaining primary vegetation
- Extent of remaining wilderness
- Leaf area index
- Percentage of live coral cover
- Proportion of local breeds at risk/not at risk/unknown
- IUCN red list of threatened species
- Living planet index
- Local species abundance
- Predatory fish biomass
- Prey fish biomass
- Proportion of fish stocks within biologically sustainable levels
- Red list index
- Wild bird index
- Mean length of fish
- Proportion of predatory fish


Output: {{ "list_of_drivers": ["driver1", "driver2"], "ebv.ind": ["EBV or indicator"], "decision": "retain"|"uncertain"|"exclude", "reason": "<1-2 sentences>" }}
```
