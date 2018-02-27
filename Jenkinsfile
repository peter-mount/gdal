// Repository name use, must end with / or be '' for none
repository= 'area51/'

// image prefix
imagePrefix = 'gdal'

// The gdal & image version
version='2.2.3'

// The architectures to build, in format recognised by docker
architectures = [ 'amd64', 'arm64v8' ]

// The slave label based on architecture
def slaveId = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'AMD64'
    case 'arm64v8':
      return 'ARM64'
    default:
      return 'amd64'
  }
}

// The docker image name
// architecture can be '' for multiarch images
def dockerImage = {
  architecture -> repository + imagePrefix + ':' +
    ( architecture=='' ? '' : ( architecture + '-' ) ) +
    version
}

// The go arch
def goarch = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'amd64'
    case 'arm32v6':
    case 'arm32v7':
      return 'arm'
    case 'arm64v8':
      return 'arm64'
    default:
      return architecture
  }
}

properties( [
  buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '7', numToKeepStr: '10')),
  disableConcurrentBuilds(),
  disableResume(),
  pipelineTriggers([
    cron( 'H H * * *')
  ])
])

def buildGdal = {
  architecture -> node( slaveId( architecture ) ) {
    stage( "Checkout " + architecture ) {
      checkout scm
      sh 'docker pull alpine:latest'
      sh 'docker pull area51/node:latest'
    }

    stage( 'Configure ' + architecture ) {
      sh 'docker build' +
        ' -t ' + dockerImage( architecture, version ) +
        ' --build-arg VERSION=' + version +
        ' --target configure' +
        ' .'
    }

    stage( 'Make ' + architecture ) {
      sh 'docker build' +
        ' -t ' + dockerImage( architecture, version ) +
        ' --build-arg VERSION=' + version +
        ' --target make' +
        ' .'
    }

    stage( 'install ' + architecture ) {
      sh 'docker build' +
        ' -t ' + dockerImage( architecture, version ) +
        ' --build-arg VERSION=' + version +
        ' --target install' +
        ' .'
    }

    stage( 'Image ' + architecture ) {
      sh 'docker build' +
        ' -t ' + dockerImage( architecture, version ) +
        ' --build-arg VERSION=' + version +
        ' --target dist' +
        ' .'
      sh 'docker build' +
        ' -t ' + dockerImage( architecture, version ) +
        ' --build-arg VERSION=' + version +
        ' --target gdal' +
        ' .'
    }

    stage( 'Publish ' + architecture ) {
      sh 'docker push ' + dockerImage( architecture, version )
    }
  }
}

def multiarch = {
  multiVersion -> stage( 'Publish multi arch' ) {
    // The manifest to publish
    multiImage = dockerImage( '', multiVersion )

    // Create/amend the manifest with our architectures
    manifests = architectures.collect { architecture -> dockerImage( architecture, version ) }
    sh 'docker manifest create -a ' + multiImage + ' ' + manifests.join(' ')

    // For each architecture annotate them to be correct
    architectures.each {
      architecture -> sh 'docker manifest annotate' +
        ' --os linux' +
        ' --arch ' + goarch( architecture ) +
        ' ' + multiImage +
        ' ' + dockerImage( architecture, version )
    }

    // Publish the manifest
    sh 'docker manifest push -p ' + multiImage
  }
}

parallel(
  'amd64': {
    buildGdal( 'amd64' )
  },
  'arm64v8': {
    buildGdal( 'arm64v8' )
  }
)

node( "AMD64" ) {
  multiarch( version )
  multiarch( 'latest' )
}
